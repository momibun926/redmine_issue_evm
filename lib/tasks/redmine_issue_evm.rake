namespace :redmine_issue_evm do
  namespace :orphans do
    desc "Show how many records of deleted projects the EVM plugin still has"
    task count: :environment do
      counts = EvmOrphanRecords.counts
      counts.each { |table, count| puts "#{table}: #{count}" }
      puts "Run redmine_issue_evm:orphans:delete to delete them." if counts.values.sum.positive?
    end

    desc "Delete the records of deleted projects that the EVM plugin still has"
    task delete: :environment do
      EvmOrphanRecords.delete!.each { |table, count| puts "#{table}: #{count} deleted" }
    end
  end
end
