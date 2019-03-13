class ConstituentsController < ApplicationController
  before_action :set_constituent, only: [:show, :edit, :update, :destroy]

  # GET /constituents
  # GET /constituents.json
  def index
    @constituents = Constituent.all
  end

  # GET /constituents/1
  # GET /constituents/1.json
  def show
  end

  # GET /constituents/new
  def new
    @constituent = Constituent.new
  end

  # GET /constituents/1/edit
  def edit
  end

  # POST /constituents
  # POST /constituents.json
  def create
    @constituent = Constituent.new(constituent_params)

    respond_to do |format|
      if @constituent.save
        format.html { redirect_to @constituent, notice: 'Constituent was successfully created.' }
        format.json { render :show, status: :created, location: @constituent }
      else
        format.html { render :new }
        format.json { render json: @constituent.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /constituents/1
  # PATCH/PUT /constituents/1.json
  def update
    respond_to do |format|
      if @constituent.update(constituent_params)
        format.html { redirect_to @constituent, notice: 'Constituent was successfully updated.' }
        format.json { render :show, status: :ok, location: @constituent }
      else
        format.html { render :edit }
        format.json { render json: @constituent.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /constituents/1
  # DELETE /constituents/1.json
  def destroy
    @constituent.destroy
    respond_to do |format|
      format.html { redirect_to constituents_url, notice: 'Constituent was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_constituent
      @constituent = Constituent.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def constituent_params
      params.fetch(:constituent, {})
    end
end
