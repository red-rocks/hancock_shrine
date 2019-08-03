#= require cropper/cropper
#= require cropper/cropper

#= require babel-polyfill/polyfill
#= require uppy/uppy

#= require_self

window.hancock_cms ||= {}
window.hancock_cms.shrine ||= {}

window.hancock_cms.shrine.checkCropAvailable = (fileInput) ->
  cacheField = fileInput.parentNode.querySelector('.cache')
  uppy = fileInput.uppy
  cropLink = fileInput.parentNode.querySelector('.crop-btn')
  removeLink = fileInput.parentNode.querySelector('.btn-remove-image')
  if cacheField.value.length == 0 and uppy.getFiles().length == 0 and !fileInput.dataset.original
    $(cropLink).hide()
    $(removeLink).hide()
  else
    $(cropLink).show()
    $(removeLink).show()


window.hancock_cms.shrine.fileUpload = (fileInput) ->
  imagePreview = fileInput.parentNode.querySelector('.img-thumbnail')
  fileInput.style.display = 'none'
  # uppy will add its own file input
  uppy = Uppy.Core(
    id: fileInput.id
    autoProceed: true
    allowMultipleUploads: true
  ).use(Uppy.FileInput, target: fileInput.parentNode
  ).use(Uppy.Informer, target: fileInput.parentNode
  ).use(Uppy.ProgressBar, target: imagePreview.parentNode
  ).use(Uppy.ThumbnailGenerator, thumbnailWidth: 400)
  
  uppy.use Uppy.XHRUpload,
    endpoint: '#{field.direct_upload[:url]}'
    formData: true
    metaFields: [
      'name'
      'crop_x'
      'crop_y'
      'crop_w'
      'crop_h'
    ]
    withCredentials: true
    responseUrlFieldName: 'url'

  uppy.on 'upload-success', (file, response) ->
    # read uploaded file data from the upload endpoint 
    console.log 'upload:success'
    console.log response.body
    metadata = response.body.data or response.body
    uploadedFileData = JSON.stringify(metadata)
    # set hidden field value to the uploaded file data so that it's submitted with the form as the attachment
    hiddenInput = fileInput.parentNode.querySelector('.cache')
    hiddenInput.value = uploadedFileData
    console.log imagePreview.src
    console.log response.body.url
    imagePreview.src = response.body.url
    console.log imagePreview.src
    
  uppy.on 'file-added', (file) ->
    console.log 'Added file', file
    # uppy.setMeta({cached_metadata: null}))
    uppy.setMeta
      crop_x: null
      crop_y: null
      crop_w: null
      crop_h: null
    checkCropAwindow.hancock_cms.shrine.vailable fileInput
    
  uppy.on 'thumbnail:generated', (file, preview) ->
    console.log 'thumbnail:generated'
    imagePreview.src = imagePreview.src or preview
    
  uppy.on 'upload', (data) ->
    imagePreview.removeAttribute 'src'
    window.hancock_cms.shrine.checkCropAvailable fileInput
    
  fileInput.classList.add 'uppy'
  fileInput.uppy = uppy
  window.hancock_cms.shrine.checkCropAvailable fileInput
  uppy


$(document).on 'rails_admin.dom_ready', ->
  $('.hancock_shrine_type [type=file]:not(.uppy, .no-uppy)').each (i, fileInput) ->
    window.hancock_cms.shrine.fileUpload fileInput


#########

window.hancock_cms.shrine.getModal = ()->
  dialog = $(
    '<div id="modal" class="modal fade">\
      <div class="modal-dialog">\
      <div class="modal-content">\
      <div class="modal-header">\
        <a href="#" class="close" data-dismiss="modal">&times;</a>\
        <h3 class="modal-header-title">...</h3>\
      </div>\
      <div class="modal-body">\
        ...\
      </div>\
      <div class="modal-footer">\
        <a href="#" class="btn cancel-action">...</a>\
        <a href="#" class="btn btn-primary save-action">...</a>\
      </div>\
      </div>\
      </div>\
    </div>')
    .modal({
      keyboard: true
      backdrop: true
      show: true
    })
    .on('hidden.bs.modal', ->
      dialog.remove()
    )
  modal = dialog.data('bs.modal')
  modal.enforceFocus()
  dialog


$(document).on "click", ".hancock_shrine_type.no-jcrop .crop-btn", (e)->
  e.preventDefault()
  fieldWrapper = $(e.currentTarget).closest('.hancock_shrine_type')
  remoteForm = $.ra.remoteForm()
  dialog = window.hancock_cms.shrine.getModal()
  dialogTitle = dialog.find('.modal-header-title')
  dialogBody = dialog.find('.modal-body')
  saveButton = dialog.find(".save-action")
  cancelButton = dialog.find(".cancel-action")

  dialogTitle.text("Обрезка")
  saveButton.text("Обрезать")
  cancelButton.text("Отменить")

  field = fieldWrapper.find('.uppy[type=file]')
  fieldCache = fieldWrapper.find('.cache[type=hidden]')
  if fieldCache.val()
    cached = JSON.parse(fieldCache.val())
    is_stored = cached.storage == "store"
    storage_path = (if (!cached.storage or is_stored) then "" else ("/" + cached.storage))
    prefix = cached.prefix || 'uploads'
    actualImageUrl = "/#{prefix}#{storage_path}/#{cached.id}"
  else
    actualImageUrl = field.data('original')

  csrf_param = document.querySelector('meta[name=csrf-param]').content
  csrf_token = document.querySelector('meta[name=csrf-token]').content

  cropper_image = "<img id='cropper-image' style='width: 100%;' src='#{actualImageUrl}'>"
  cropper_image_wrapper = "<div style='max-width: 100%;'>#{cropper_image}</div>"
  action = field.closest("form").attr("action").split("?")[0]
  if action.endsWith("/edit")
    form_action = action.replace(/\/edit$/i, "/hancock_shrine_crop")
    cropper_form = [
      "<form action='#{form_action}' data-remote='true' id='cropper-form' accept-charset='UTF-8' method='post'>",
      "<input type='hidden' name='#{csrf_param}' value='#{csrf_token}'>",

      "<input type='hidden' name='name' value='image'>",
      "<input type='hidden' name='image' value='#{JSON.stringify(cached) || ""}'>"

      "<input type='hidden' name='crop_x' value=''>",
      "<input type='hidden' name='crop_y' value=''>",
      "<input type='hidden' name='crop_w' value=''>",
      "<input type='hidden' name='crop_h' value=''>",
      "</form>"
    ].join("")

  # WTF
  setTimeout ->
    dialogBody.html(cropper_image_wrapper + (cropper_form || ""))

    $image = dialogBody.find('#cropper-image')
    $image.load ->
      $image.cropper({
        aspectRatio: JSON.parse(field.data('rails-admin-crop-options').aspectRatio),
        # viewMode: 1,
        # scalable: false,
        # zoomable: false
      })
  , 500

  
  

  saveButton.on 'click', (e)->
    e.preventDefault()
    $image = dialogBody.find('#cropper-image')
    cropper = $image.data('cropper')

    scaleX = cropper.imageData.naturalWidth / cropper.imageData.width
    scaleY = cropper.imageData.naturalHeight / cropper.imageData.height
    cropBoxData = cropper.cropBoxData

    cropData = {
      crop_x: cropBoxData.left * scaleX
      crop_y: cropBoxData.top * scaleX
      crop_w: cropBoxData.width * scaleX
      crop_h: cropBoxData.height * scaleX
    }
    

    # TODO: WTF !!!!
    $cropper_form = $('#cropper-form')
    if $cropper_form.length > 0 # if "/edit" action
      $cropper_form.on "ajax:error ajax:complete", (e, xhr, status, error)->
        if error
          alert(error)
          console.log(error)
          console.log(xhr)
        else
          data = xhr.responseJSON
          fieldCache.val('')
          field.data('original', data.original.url)
          
          console.log(data)
          thumb = (data.thumb || data.thumbnail || data.main || data.original)
          console.log(thumb)
          preview = fieldCache.siblings('.toggle').find('.preview img')
          preview.attr('src', thumb.url)

          urls_list_block = fieldCache.siblings('.urls_list_block')
          for style, style_opts of data
            a = urls_list_block.find(".url_block.style-#{style} a")
            a.attr('href', style_opts.url).text(style_opts.id)
        dialog.modal('hide')
      ########
      $cropper_form.find('[name="crop_x"]').val(cropData.crop_x)
      $cropper_form.find('[name="crop_y"]').val(cropData.crop_y)
      $cropper_form.find('[name="crop_w"]').val(cropData.crop_w)
      $cropper_form.find('[name="crop_h"]').val(cropData.crop_h)
      $cropper_form.submit()
      ########

    else # if "/new" action
      uppy = field[0].uppy
      uppy.setMeta(cropData)

      uppy.retryUpload(uppy.getFiles()[0].id).then (result) -> 
        console.info('Successful uploads:', result.successful)

        if (result.failed.length > 0) 
          console.error('Errors:')
          result.failed.forEach (file) -> 
            console.error(file.error)
      
        dialog.modal('hide')
      

  cancelButton.on 'click', (e)->
    e.preventDefault()
    dialog.modal('hide')
  
  return false
