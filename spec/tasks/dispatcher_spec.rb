if RUBY_PLATFORM != 'opal'
  class TestTask < Volt::Task
    def allowed_method(arg1, arg2)
      'yes' + arg1 + arg2
    end
  end

  describe Volt::Dispatcher do
    before do
      Volt.logger = spy('Volt::VoltLogger')
    end

    after do
      # Cleanup, make volt make a new logger.  Otherwise this will leak out.
      Volt.logger = nil
    end

    it 'should only allow method calls on Task or above in the inheritance chain' do
      channel = double('channel')

      expect(channel).to receive(:send_message).with('response', 0, 'yes it works', nil)

      Volt::Dispatcher.new.dispatch(channel, [0, 'TestTask', :allowed_method, {}, ' it', ' works'])
    end

    it 'should not allow eval' do
      channel = double('channel')

      expect(channel).to receive(:send_message).with('response', 0, nil, RuntimeError.new('unsafe method: eval'))

      Volt::Dispatcher.new.dispatch(channel, [0, 'TestTask', :eval, '5 + 10'])
    end

    it 'should not allow instance_eval' do
      channel = double('channel')

      expect(channel).to receive(:send_message).with('response', 0, nil, RuntimeError.new('unsafe method: instance_eval'))

      Volt::Dispatcher.new.dispatch(channel, [0, 'TestTask', :instance_eval, '5 + 10'])
    end

    it 'should not allow #methods' do
      channel = double('channel')

      expect(channel).to receive(:send_message).with('response', 0, nil, RuntimeError.new('unsafe method: methods'))

      Volt::Dispatcher.new.dispatch(channel, [0, 'TestTask', :methods])
    end

    it 'should log an info message before and after the dispatch' do
      channel = double('channel')

      allow(channel).to receive(:send_message).with('response', 0, 'yes it works', nil)
      expect(Volt.logger).to receive(:log_dispatch)

      Volt::Dispatcher.new.dispatch(channel, [0, 'TestTask', :allowed_method, {}, ' it', ' works'])
    end

    it 'closes the channel' do
      dispatcher = Volt::Dispatcher.new
      channel    = Volt::ChannelStub.new
      # This doesn't do much except find typos, which is the only reason
      # I haven't deleted it. Work in progress -@RickCarlino
      this_spec_needs_improvement = dispatcher.close_channel(channel)
    end
  end
end
