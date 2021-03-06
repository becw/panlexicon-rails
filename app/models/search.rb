class Search
  include ActiveModel::Model
  attr_reader :string, :words

  validates :string, presence: true
  validate :words_exist
  validate :words_have_intersecting_groups

  MAX_WORDS = 80
  MAX_WEIGHT = 8

  def initialize(string)
    @string = string
  end

  def searched_words
    @searched_words ||= split_string.map do |name|
      # TODO: put an index on this in the database
      Word.where('LOWER(name) = ?', name.downcase).first
    end.compact
  end

  def results
    @results ||= weight_related_words
  end

  def group_ids
    @group_ids ||= Array(searched_words.map { |t| t.groups.pluck(:id) }.inject(:&))
  end

  def missing_words
    @mising_words ||= split_string.map(&:downcase) - searched_words.map(&:name).map(&:downcase)
  end

  private

  def split_string
    string.split(',').map(&:strip)
  end

  def weight_related_words
    ActiveRecord::Base.connection.execute("
      SELECT word.id,
             word.name,
             grouping.groups_count AS groups_count,
             ntile(#{ MAX_WEIGHT }) OVER (ORDER BY grouping.groups_count) AS weight
        FROM (
          SELECT word_id, COUNT(*) as groups_count FROM groupings
          WHERE group_id IN (#{ group_ids.join(',') })
          GROUP BY word_id ORDER BY groups_count DESC LIMIT #{ MAX_WORDS }
        ) grouping
        LEFT JOIN words word ON word.id = grouping.word_id
        ORDER BY word.name;
    ").map { |row| WeightedWord.new(row) }
  end

  def words_exist
    return unless missing_words.size > 0
    errors.add :string, "#{ sadness_synonym.titleize }. "\
                        "The #{ 'word'.pluralize(missing_words.size) } "\
                        "<strong>#{ missing_words.join(', ') }</strong> "\
                        "#{ missing_words.size == 1 ? 'is' : 'are' } not in our dictionary."
  end

  def words_have_intersecting_groups
    return unless group_ids.size == 0
    errors.add :groups, "#{ sadness_synonym.titleize }. "\
                        'No commonality can be found between '\
                        "<strong>#{ string }</strong>."\
  end

  def sadness_synonym
    %w[sadness despair woe anguish ache distress].sample
  end
end
