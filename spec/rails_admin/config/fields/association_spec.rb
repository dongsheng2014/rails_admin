require 'spec_helper'

describe RailsAdmin::Config::Fields::Association do
  describe '#pretty_value' do
    let(:player) { FactoryBot.create(:player, name: '<br />', team: FactoryBot.create(:team)) }
    let(:field) { RailsAdmin.config('Team').fields.detect { |f| f.name == :players } }
    let(:view) { ActionView::Base.new.tap { |d| allow(d).to receive(:action).and_return(nil) } }
    subject { field.with(object: player.team, view: view).pretty_value }

    context 'when the link is disabled' do
      it 'does not expose non-HTML-escaped string' do
        is_expected.to be_html_safe
        is_expected.to eq '&lt;br /&gt;'
      end
    end
  end

  describe '#removable?', active_record: true do
    context 'with non-nullable foreign key' do
      let(:field) { RailsAdmin.config('FieldTest').fields.detect { |f| f.name == :nested_field_tests } }
      it 'is false' do
        expect(field.removable?).to be false
      end
    end

    context 'with nullable foreign key' do
      let(:field) { RailsAdmin.config('Team').fields.detect { |f| f.name == :players } }
      it 'is true' do
        expect(field.removable?).to be true
      end
    end

    context 'with polymorphic has_many' do
      let(:field) { RailsAdmin.config('Player').fields.detect { |f| f.name == :comments } }
      it 'does not break' do
        expect(field.removable?).to be true
      end
    end

    context 'with has_many through' do
      before do
        class TeamWithHasManyThrough < Team
          has_many :drafts
          has_many :draft_players, through: :drafts, source: :player
        end
      end
      let(:field) { RailsAdmin.config('TeamWithHasManyThrough').fields.detect { |f| f.name == :draft_players } }
      it 'does not break' do
        expect(field.removable?).to be true
      end
    end
  end

  describe 'method_name' do
    context 'with has_and_belongs_to_many - active record' do
      before do
        class Author
          has_and_belongs_to_many :articles
        end
        class Article
          has_and_belongs_to_many :authors
        end
      end
      let(:field) { RailsAdmin.config('Article').fields.detect { |f| f.name == :authors } }
      it 'has correct method_name' do
        expect(field.allowed_methods?).to eq [:author_ids]
      end
    end

    context 'with has_and_belongs_to_many - mongoid' do
      before do
        class Author1
          include Mongoid::Document
          field :name, type: String
          field :fullname, type: String
        end
        class Article1
          include Mongoid::Document

          field :title, type: String
          field :content, type: String

          has_and_belongs_to_many :author1s, inverse_of: nil
        end
      end
      let(:field) { RailsAdmin.config('Article1').fields.detect { |f| f.name == :author1s } }
      it 'has correct method_name' do
        expect(field.allowed_methods?).to eq [:author1_ids]
      end
    end

    context 'with has_and_belongs_to_many and customized foreign_key' do
      before do
        class Author
          include Mongoid::Document
          field :name, type: String
          field :fullname, type: String
        end
        class Article
          include Mongoid::Document

          field :title, type: String
          field :content, type: String

          has_and_belongs_to_many :_authors, class_name: "Author", inverse_of: nil, primary_key: 'name', foreign_key: "authors"
        end
      end
      let(:field) { RailsAdmin.config('Article').fields.detect { |f| f.name == :_authors } }
      it 'has correct method_name' do
        expect(field.allowed_methods?).to eq [:authors]
      end
    end
  end
end
