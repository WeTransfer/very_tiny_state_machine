# very_tiny_state_machine

[![Build Status](https://travis-ci.org/WeTransfer/very_tiny_state_machine.svg?branch=master)](https://travis-ci.org/WeTransfer/very_tiny_state_machine)

For when the others are not tiny enough.

The entire state machine lives in a separate variable, and does not pollute the class or the module of the caller.
The state machine has the ability to dispatch callbacks when states are switched, and the callbacks
are dispatched to the given object as messages.

    @automaton = VeryTinyStateMachine.new(:initialized, self)
    @automaton.permit_state :processing, :closing, :closed
    @automaton.permit_transition :initialized => :processing, :processing => :closing
    @automaton.permit_transition :closing => :closed
    
    # Then, lower down the code
    @automaton.transition! :processing 

The object supplied as the optional second argument will receive messages when states are switched around,
in the following order (using the state machine from the previous example):
   
    # self.leaving_initialized_state
    # self.entering_processing_state
    # self.transitioning_from_initialized_to_processing_state
    # ..the state variable is switched here
    # self.after_transitioning_from_initialized_to_processing_state
    # self.after_leaving_initialized_state
    # self.after_entering_processing_state

You can see in which state the machine is in:

    @automaton.in_state?(:processing) #=> true
    @automaton.in_state?(:initialized) #=> false

and state machine has your back if you want to do something invalid:

    @automaton.transition :initialized # Will raise TinyStateMachine::InvalidFlow
    @automaton.transition :something_odd # Will raise TinyStateMachine::UnknownState

## Contributing to very_tiny_state_machine
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2016 WeTransfer. See LICENSE.txt for further details.

