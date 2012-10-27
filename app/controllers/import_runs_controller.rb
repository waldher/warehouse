class ImportRunsController < ApplicationController
  def index
    @import_runs = ImportRun.order("created_at desc")
  end
end
