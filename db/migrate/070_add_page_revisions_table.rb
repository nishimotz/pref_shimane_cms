class AddPageRevisionsTable < ActiveRecord::Migration
  def self.up
    create_table(:page_revisions) do |t|
      t.column(:page_id, :integer)
      t.column(:user_id, :integer)
      t.column(:last_modified, :datetime)
      t.column(:user_name, :string)
      t.column(:tel, :string)
      t.column(:email, :string)
      t.column(:comment, :text)
    end
  end

  def self.down
    drop_table(:page_revisions)
  end
end
