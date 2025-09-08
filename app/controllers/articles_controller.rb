class ArticlesController < ApplicationController
  before_action :set_article, only: %i[ show edit update destroy ]

  # GET /articles or /articles.json
  def index
    @articles = Article.all
  end

  # GET /articles/1 or /articles/1.json
  def show
  end

  # GET /articles/new
  def new
    @article = Article.new
  end

  # GET /articles/1/edit
  def edit
  end

  # POST /articles or /articles.json
  def create
    @article = Article.new(article_params)

    respond_to do |format|
      if @article.save
        format.html { redirect_to @article, notice: "Article was successfully created." }
        format.json { render :show, status: :created, location: @article }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1 or /articles/1.json
  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to @article, notice: "Article was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @article }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1 or /articles/1.json
  def destroy
    @article.destroy!

    respond_to do |format|
      format.html { redirect_to articles_path, notice: "Article was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def upload_image
    Rails.logger.info "---- DEBUG: RUNNING NEW UPLOAD_IMAGE METHOD ----"
    file = params[:file]
    if file
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename)
      Rails.logger.info "---- DEBUG: BLOB SIGNED ID IS: #{blob.signed_id} ----"
      render json: {
        success: 1,
        file: {
          url: url_for(blob),
          signed_id: blob.signed_id # <-- ADDED
        }
      }
    else
      render json: {success: 0, message: "No file provided"}, status: :unprocessable_entity
    end
  end

  def fetch_image_url
    Rails.logger.info "---- DEBUG: RUNNING Fetch METHOD ----"

    url = params[:url]
    if url
      io = URI.open(url)
      filename = File.basename(URI.parse(url).path)
      blob = ActiveStorage::Blob.create_and_upload!(io: io, filename: filename)
      Rails.logger.info "---- DEBUG: BLOB SIGNED ID IS: #{blob.signed_id} ----"
      render json: {
        success: 1,
        file: {
          url: url_for(blob),
          signed_id: blob.signed_id # <-- ADDED
        }
      }
    else
      render json: { success: 0, message: 'No URL provided' }, status: :unprocessable_entity
    end
  rescue => e
    render json: { success: 0, message: e.message }, status: :unprocessable_entity
  end

  def upload_file
    Rails.logger.info "---- DEBUG: RUNNING UPLOAD FILE METHOD ----"
    file = params[:file]
    if file
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename)
      Rails.logger.info "---- DEBUG: BLOB SIGNED ID IS: #{blob.signed_id} ----"
      render json: {
        success: 1,
        file: {
          url: url_for(blob),
          signed_id: blob.signed_id, # <-- ADDED
          size: blob.byte_size,
          name: blob.filename.to_s,
          title: blob.filename.to_s,
          extension: blob.filename.extension
        }
      }
    else
      render json: { success: 0, message: 'No file provided' }, status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.friendly.find(params.expect(:id))

      #problem ::------- edit is not loading
      # If an old id or a numeric id was used to find the record, then
      # the request path will not match the post_path, and we should do
      # a 301 redirect that uses the current friendly id.
      if action_name == "show" && request.path != article_path(@article)
        redirect_to @article, status: :moved_permanently
      end

    end

    # Only allow a list of trusted parameters through.
    def article_params
      params.expect(article: [ :title, :content,:topic_name ])
    end
end
