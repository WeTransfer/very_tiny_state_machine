# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe VeryTinyStateMachine do
  describe '#initialize' do
    it 'creates a state machine and sets its initial state' do
      machine = described_class.new(:started)
      expect(machine).to be_known(:started)
      expect(machine).to be_in_state(:started)
    end

    it 'accepts a second argument' do
      acceptor = double('Callbacks')
      described_class.new(:started, acceptor)
    end
  end

  describe '#permit_state' do
    it 'makes the state known to the state machine' do
      machine = described_class.new(:started)

      first_result_of_permission = machine.permit_state :closed
      second_result_of_permission = machine.permit_state :closed, :open

      expect(first_result_of_permission).to eq(Set.new([:closed]))
      expect(second_result_of_permission).to eq(Set.new([:open]))

      expect(machine).to be_known(:started)
      expect(machine).to be_known(:closed)
      expect(machine).to be_known(:open)
    end

    it 'does not permit transitions to the newly added state by default' do
      machine = described_class.new(:started)
      machine.permit_state :running

      expect(machine).not_to be_may_transition_to(:running)

      expect do
        machine.transition! :running
      end.to raise_error(described_class::InvalidFlow, /Cannot change states from started to running/)
    end
  end

  describe '#permit_transition' do
    it 'raises on an unknown state specified as source' do
      machine = described_class.new(:started)
      expect do
        machine.permit_transition unknown: :started
      end.to raise_error(VeryTinyStateMachine::UnknownState)
    end

    it 'raises on an unknwon state specified as destination' do
      machine = described_class.new(:started)
      expect do
        machine.permit_transition started: :unknown
      end.to raise_error(VeryTinyStateMachine::UnknownState)
    end

    it 'returns a Set of transitions permitted after the call' do
      machine = described_class.new(:started)
      machine.permit_state :running

      result = machine.permit_transition started: :running

      expect(result).to be_kind_of(Set)
      expect(result).to eq(Set.new([{ started: :running }]))

      adding_second_time = machine.permit_transition started: :running
      expect(adding_second_time).to be_kind_of(Set)
      expect(adding_second_time).to be_empty
    end

    it 'is able to perform the transition after it has been defined' do
      machine = described_class.new(:started)
      machine.permit_state :running
      machine.permit_transition started: :running
      machine.transition! :running
    end

    it 'allows the transition from a state to itself only explicitly' do
      machine = described_class.new(:started)
      expect do
        machine.transition! :started
      end.to raise_error(described_class::InvalidFlow)

      machine.permit_transition started: :started
      machine.transition! :started
      expect(machine.flow_so_far).to eq(%i[started started])
    end
  end

  describe '#flow_so_far' do
    it 'records the flow' do
      machine = described_class.new(:started)
      machine.permit_state :running, :stopped
      machine.permit_transition started: :running, running: :stopped, stopped: :started

      machine.transition! :running
      machine.transition! :stopped
      machine.transition! :started

      flow = machine.flow_so_far
      expect(flow).to eq(%i[started running stopped started])

      flow << nil
      expect(flow).not_to eq(machine.flow_so_far), 'The flow returned should not link to the mutable array in the machine'
    end
  end

  describe '#transition!' do
    it 'returns the previous state the object was in' do
      machine = described_class.new(:started)
      machine.permit_state :running
      machine.permit_transition started: :running
      transitioned_from = machine.transition! :running
      expect(transitioned_from).to eq(:started)
    end

    it 'sends all of the callbacks if the object responds to them' do
      fake_acceptor = double('Callback handler')
      allow(fake_acceptor).to receive(:respond_to?) { |_method_name, honor_private_and_public|
        expect(honor_private_and_public).to eq(true)
        true
      }

      machine = described_class.new(:started, fake_acceptor)
      machine.permit_state :running, :stopped
      machine.permit_transition started: :running, running: :stopped, stopped: :started

      expect(fake_acceptor).to receive(:before_every_transition).with(:started, :running)
      expect(fake_acceptor).to receive(:leaving_started_state)
      expect(fake_acceptor).to receive(:entering_running_state)
      expect(fake_acceptor).to receive(:transitioning_from_started_to_running)
      expect(fake_acceptor).to receive(:after_transitioning_from_started_to_running_state)
      expect(fake_acceptor).to receive(:after_leaving_started_state)
      expect(fake_acceptor).to receive(:after_entering_running_state)
      expect(fake_acceptor).to receive(:after_every_transition).with(:started, :running)

      machine.transition! :running
    end

    it 'dispatches callbacks to private methods as well' do
      acceptor = Class.new do
        def called?
          @entered_state
        end

                   private

        def entering_running_state
          @entered_state = true
        end
      end.new

      machine = described_class.new(:started, acceptor)
      machine.permit_state :running, :stopped
      machine.permit_transition started: :running, running: :stopped, stopped: :started

      machine.transition! :running
      expect(acceptor).to be_called
    end

    it 'does not send the messages to an acceptor that does not respond to those messages' do
      fake_acceptor = double('Callback handler')
      allow(fake_acceptor).to receive(:respond_to?) { |_method_name, honor_private_and_public|
        expect(honor_private_and_public).to eq(true)
        false
      }

      machine = described_class.new(:started, fake_acceptor)
      machine.permit_state :running, :stopped
      machine.permit_transition started: :running, running: :stopped, stopped: :started

      machine.transition! :running
    end
  end

  describe '#transition_or_maintain!' do
    it 'does not perform any transitions if the object is already in the requisite state' do
      machine = described_class.new(:perfect)
      machine.transition_or_maintain! :perfect
      expect(machine.flow_so_far).to eq([:perfect])
    end

    it 'does perform a transition if the object is not in the requisite state' do
      machine = described_class.new(:perfect)
      machine.permit_state :perfect, :improving
      machine.permit_transition perfect: :improving, improving: :perfect

      machine.transition_or_maintain! :improving
      expect(machine.flow_so_far).to eq(%i[perfect improving])
    end
  end

  describe '#expect!' do
    it 'returns true when the machine is in the requisite state' do
      machine = described_class.new(:started)
      expect(machine.expect!(:started)).to eq(true)
    end

    it 'raises an exception if the machine is not in that state' do
      machine = described_class.new(:started)
      expect do
        machine.expect!(:running)
      end.to raise_error(VeryTinyStateMachine::InvalidFlow, 'Must be in :running state, but was in :started')
    end
  end
end
