class WeightedWord
  extend Forwardable

  attr_reader :word, :groups_count, :weight, :search
  def_delegators :@word, :id, :name

  def initialize(attributes = {}, options = {})
    attributes = attributes.with_indifferent_access

    @word = Word.instantiate attributes
    @groups_count = attributes[:groups_count].to_i
    @weight = attributes[:weight].to_i

    # Context is necessary too
    @search = options.fetch(:search, nil)
  end
end
