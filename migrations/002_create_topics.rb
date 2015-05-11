Sequel.migration do
  up do
    create_table(:topics) do
      primary_key :id
      String :topic
      String :description
      String :time
    end
  end

  down do
    drop_table(:topics)
  end
end