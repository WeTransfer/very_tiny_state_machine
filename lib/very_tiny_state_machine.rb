# frozen_string_literal: true

require 'set'

# A mini state machine object that can be used to track a state flow.
#
# The entire state machine lives in a separate variable, and does not pollute the
# class or the module of the caller.
# The state machine has the ability to dispatch callbacks when states are switched, the callbacks
# are dispatched to the given object.
#
#     @automaton = VeryTinyStateMachine.new(:initialized, self)
#     @automaton.permit_state :processing, :closing, :closed
#     @automaton.permit_transition :initialized => :processing, :processing => :closing
#     @automaton.permit_transition :closing => :closed
#
#     # Then, lower down the code
#     @automaton.transition! :processing
#
#     # This switches the internal state of the machine, and dispatches the following method
#     # calls on the object given as the second argument to the constructor, in the following order:
#
#     # self.leaving_initialized_state
#     # self.entering_processing_state
#     # self.transitioning_from_initialized_to_processing_state
#     # ..the state variable is switched here
#     # self.after_transitioning_from_initialized_to_processing_state
#     # self.after_leaving_initialized_state
#     # self.after_entering_processing_state
#
#     @automaton.transition :initialized # Will raise TinyStateMachine::InvalidFlow
#     @automaton.transition :something_odd # Will raise TinyStateMachine::UnknownState
#
#     @automaton.in_state?(:processing) #=> true
#     @automaton.in_state?(:initialized) #=> false
class VeryTinyStateMachine
  VERSION = '2.2.0'
  INCLUDE_PRIVATES = true
  InvalidFlow = Class.new(StandardError) # Gets raised when an impossible transition gets requested
  UnknownState = Class.new(StandardError) # Gets raised when an unknown state gets requested

  # Initialize a new TinyStateMachine, with the initial state and the object that will receive callbacks.
  #
  # @param initial_state[#to_sym] the initial state of the state machine
  # @param object_handling_callbacks[#send, #respond_to?] the callback handler that will receive transition notifications
  def initialize(initial_state, object_handling_callbacks = nil)
    @state = initial_state.to_sym
    @flow = [@state]
    @permitted_states = Set.new([initial_state])
    @permitted_transitions = Set.new
    @callbacks_via = object_handling_callbacks
  end

  # Permit a single state or multiple states
  #
  # @param states [Array] states to permit
  # @return [Set] the Set of states added to permitted states as the result of the call
  def permit_state(*states)
    states_to_permit = Set.new(states.map(&:to_sym))
    will_be_added = states_to_permit - @permitted_states
    @permitted_states += states_to_permit
    will_be_added
  end

  # Permit states and transitions between them, all in one call
  #
  #    m.permit_states_and_transitions(:created => [:rejected, :accepted])
  #
  # Be careful with hash key shadowing. This call:
  #
  #    m.permit_states_and_transitions(:created => :rejected, :created => :accepted)
  #
  # will not do what you expect - the last keyword argument will shadow the
  # first one and thus only the {:created => :accepted} transition - and only
  # the [:created, :accepted] states will end up being registered.
  #
  # @param **states_to_states [Hash] a mapping from one state the machine may go into and one or multiple states that can be reached from that state
  # @return self
  def permit_states_and_transitions(**initial_states_to_destination_states)
    initial_states_to_destination_states.each_pair do |one_or_more_source_states, one_or_more_destination_states|
      sources = Array(one_or_more_source_states)
      destinations = Array(one_or_more_destination_states)
      sources.each do |src|
        destinations.each do |dest|
          permit_state(src, dest)
          permit_transition(src => dest)
        end
      end
    end
    self
  end

  # Permit a transition from one state to another. If you need to add multiple transitions
  # from the same state, just call the method multiple times:
  #
  #     @machine.permit_transition :initialized => :failed, :running => :closed
  #     @machine.permit_transition :initialized => :running
  #
  # @param from_to_hash[Hash] the transitions to allow
  # @return [Array] the list of states added to permitted states
  def permit_transition(from_to_hash)
    transitions_to_permit = Set.new
    from_to_hash.each_pair do |from_state, to_state|
      raise UnknownState, from_state unless @permitted_states.include?(from_state.to_sym)
      raise UnknownState, to_state unless @permitted_states.include?(to_state.to_sym)

      transitions_to_permit << { from_state.to_sym => to_state.to_sym }
    end
    additions = transitions_to_permit - @permitted_transitions
    @permitted_transitions += transitions_to_permit
    additions
  end

  # Tells whether the state is known to this state machine
  #
  # @param state[Symbol,String] the state to check for
  # @return [Boolean] whether the state is known
  def known?(state)
    @permitted_states.include?(state.to_sym)
  end

  # Tells whether a transition is permitted to the given state.
  #
  # @param to_state[Symbol,String] state to transition to
  # @return [Boolean] whether the state can be transitioned to
  def may_transition_to?(to_state)
    to_state = to_state.to_sym
    transition = { @state => to_state.to_sym }
    @permitted_states.include?(to_state) && @permitted_transitions.include?(transition)
  end

  # Tells whether the state machine is in a given state at the moment
  #
  # @param requisite_state [Symbol,String] name of the state to check for
  # @return [Boolean] whether the machine is in that state currently
  def in_state?(requisite_state)
    @state == requisite_state.to_sym
  end

  # Ensure the machine is in a given state, and if it isn't raise an InvalidFlow
  #
  # @param requisite_state[#to_sym] the state to verify
  # @raise InvalidFlow
  # @return [TrueClass] true if the machine is in the requisite state
  def expect!(requisite_state)
    unless requisite_state.to_sym == @state
      raise InvalidFlow, "Must be in #{requisite_state.inspect} state, but was in #{@state.inspect}"
    end

    true
  end

  # Transition to a given state. Will raise an InvalidFlow exception if the transition is impossible.
  # Additionally, if you want to transition to a state that is already activated, an InvalidFlow will
  # be raised if you did not permit this transition explicitly. If you want to transition to a state OR
  # stay in it if it is already active use {TinyStateMachine#transition_or_maintain!}
  #
  #
  # During transitions the before callbacks will be called on the @callbacks_via instance variable. If you are
  # transitioning from "initialized" to "processing" for instance, the following callbacks will be dispatched:
  #
  # * leaving_initialized_state
  # * entering_processing_state
  # * transitioning_from_initialized_to_processing_state
  # ..the state variable is switched here
  # * after_transitioning_from_initialized_to_processing_state
  # * after_leaving_initialized_state
  # * after_entering_processing_state
  #
  # The return value of the callbacks does not matter.
  #
  # @param new_state[#to_sym] the state to transition to.
  # @return [Symbol] the state that the machine has just left
  # @raise InvalidFlow
  def transition!(new_state)
    new_state = new_state.to_sym

    raise UnknownState, new_state.inspect unless known?(new_state)

    if may_transition_to?(new_state)
      dispatch_callbacks_before_transition(new_state) if @callbacks_via

      previous = @state
      @state = new_state.to_sym
      @flow << new_state.to_sym

      dispatch_callbacks_after_transition(previous) if @callbacks_via
      previous
    else
      raise InvalidFlow,
            "Cannot change states from #{@state} to #{new_state} (flow so far: #{@flow.join(' > ')})"
    end
  end

  # Transition to a given state. If the machine already is in that state, do nothing.
  # If the transition has to happen (the requested state is different than the current)
  # transition! will be called instead.
  #
  # @see TinyStateMachine#transition!
  # @param new_state[Symbol,String] the state to transition to.
  # @raise InvalidFlow
  # @return [void]
  def transition_or_maintain!(new_state)
    return if in_state?(new_state)

    transition! new_state
  end

  # Returns the flow of the transitions the machine went through so far
  #
  # @return [Array] the array of states
  def flow_so_far
    @flow.dup
  end

  private

  def dispatch_callbacks_after_transition(from)
    to = @state
    if @callbacks_via.respond_to?("after_transitioning_from_#{from}_to_#{to}_state", INCLUDE_PRIVATES)
      @callbacks_via.send("after_transitioning_from_#{from}_to_#{to}_state")
    end

    if @callbacks_via.respond_to?("after_leaving_#{from}_state", INCLUDE_PRIVATES)
      @callbacks_via.send("after_leaving_#{from}_state")
    end

    if @callbacks_via.respond_to?("after_entering_#{to}_state", INCLUDE_PRIVATES)
      @callbacks_via.send("after_entering_#{to}_state")
    end

    if @callbacks_via.respond_to?(:after_every_transition, INCLUDE_PRIVATES)
      @callbacks_via.send(:after_every_transition, from, to)
    end
  end

  def dispatch_callbacks_before_transition(to)
    from = @state

    if @callbacks_via.respond_to?(:before_every_transition, INCLUDE_PRIVATES)
      @callbacks_via.send(:before_every_transition, from, to)
    end

    if @callbacks_via.respond_to?("leaving_#{from}_state", INCLUDE_PRIVATES)
      @callbacks_via.send("leaving_#{from}_state")
    end

    if @callbacks_via.respond_to?("entering_#{to}_state", INCLUDE_PRIVATES)
      @callbacks_via.send("entering_#{to}_state")
    end

    if @callbacks_via.respond_to?("transitioning_from_#{from}_to_#{to}", INCLUDE_PRIVATES)
      @callbacks_via.send("transitioning_from_#{from}_to_#{to}")
    end
  end
end
