# frozen_string_literal: true

module RuboCop
  module Cop
    module Minitest
      # This cop checks for deprecated global expectations
      # and autocorrects them to use expect format.
      #
      # @example
      #   # bad
      #   musts.must_equal expected_musts
      #   wonts.wont_match expected_wonts
      #   musts.must_raise TypeError
      #
      #   # good
      #   _(musts).must_equal expected_musts
      #   _(wonts).wont_match expected_wonts
      #   _ { musts }.must_raise TypeError
      class GlobalExpectations < Cop
        MSG = 'Use `%<preferred>s` instead.'

        VALUE_MATCHERS = %i[
          must_be_empty must_equal must_be_close_to must_be_within_delta
          must_be_within_epsilon must_include must_be_instance_of must_be_kind_of
          must_match must_be_nil must_be must_respond_to must_be_same_as
          path_must_exist path_wont_exist wont_be_empty wont_equal wont_be_close_to
          wont_be_within_delta wont_be_within_epsilon wont_include wont_be_instance_of
          wont_be_kind_of wont_match wont_be_nil wont_be wont_respond_to wont_be_same_as
        ].freeze

        BLOCK_MATCHERS = %i[must_output must_raise must_be_silent must_throw].freeze

        MATCHERS_STR = (VALUE_MATCHERS + BLOCK_MATCHERS).map do |m|
          ":#{m}"
        end.join(' ').freeze

        def_node_matcher :global_expectation?, <<~PATTERN
          (send {
            (send _ _)
            ({lvar ivar cvar gvar} _)
            (send {(send _ _) ({lvar ivar cvar gvar} _)} _ _)
          } {#{MATCHERS_STR}} ...)
        PATTERN

        def on_send(node)
          return unless global_expectation?(node)

          message = format(MSG, preferred: preferred_receiver(node))
          add_offense(node, location: node.receiver.source_range, message: message)
        end

        def autocorrect(node)
          return unless global_expectation?(node)

          lambda do |corrector|
            receiver = node.receiver.source_range

            if BLOCK_MATCHERS.include?(node.method_name)
              corrector.insert_before(receiver, '_ { ')
              corrector.insert_after(receiver, ' }')
            else
              corrector.insert_before(receiver, '_(')
              corrector.insert_after(receiver, ')')
            end
          end
        end

        private

        def preferred_receiver(node)
          source = node.receiver.source
          if BLOCK_MATCHERS.include?(node.method_name)
            "_ { #{source} }"
          else
            "_(#{source})"
          end
        end
      end
    end
  end
end
