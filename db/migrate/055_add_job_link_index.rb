class AddJobLinkIndex < ActiveRecord::Migration
  def self.up
    add_index(:jobs, :action)
    add_index(:jobs, :arg1)
  end

  def self.down
    # the following will not work with rails-1.0 due to its bug.
    # remove_index(:jobs, :column => :arg1)
    # remove_index(:jobs, :column => :action)
    remove_index(:jobs, :arg1)
    remove_index(:jobs, :action)
  end
end
