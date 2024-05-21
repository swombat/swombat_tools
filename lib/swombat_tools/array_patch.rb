module SwombatTools
  module ArrayPatch
    extend ActiveSupport::Concern

    included do
      def except(x)
        self.reject { |_x| _x == x }
      end

      def in_chunks(chunks)
        chunk_length = (self.length.to_f / chunks)+1
        self.in_groups_of(chunk_length.to_i)
      end

      def randomize
        self.sort_by { |x| rand }
      end
    end
  end
end
