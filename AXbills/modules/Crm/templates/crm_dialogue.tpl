<script src='/styles/default/js/modules/crm/crm.fileUploader.js'></script>
<link rel='stylesheet' href='/styles/default/css/modules/crm/crm.dialogue.css'>

<input type='hidden' id='ADMIN_AVATAR_LINK' name='ADMIN_AVATAR_LINK' value='%ADMIN_AVATAR_LINK%'>
<input type='hidden' id='USER_AVATAR_LINK' name='USER_AVATAR_LINK' value='%USER_AVATAR_LINK%'>
<input type='hidden' id='AID' name='AID' value='%AID%'>
<input type='hidden' id='DIALOGUE_ID' name='DIALOGUE_ID' value='%DIALOGUE_ID%'>
<input type='hidden' id='LAST_MESSAGE_FROM_AID' name='LAST_MESSAGE_FROM_AID' value='%LAST_MESSAGE_FROM_AID%'>
<div class='row'>
  <div class='col-md-10'>
    <div class='container-fluid h-100'>
      <div class='row justify-content-center h-100'>

        <div class='col-md-12 col-xl-12 chat'>
          <div class='card'>
            <div class='card-header'>
              <h4 class='card-title'>%LEAD_FIO%</h4>
            </div>
            <div class='card-body msg_card_body pb-1' id='msg_block'>
              %MESSAGES%
            </div>
            <div class='card-footer'>
              <div class='row'>
                <div class='col-xl-6 col-lg-12' id='fileListContainer'>
                </div>
              </div>
              <div class='row'>
                <div class='col-md-9'>
                  <div class='dialogue-files-container'>
                    <textarea class='form-control type_msg' placeholder='_{CRM_ENTER_YOUR_MESSAGE}_'
                              id='message-textarea' %DISABLE_TEXTAREA%></textarea>
                    <span class='icon' id='fileInput'><i class='cursor-pointer fas fa-paperclip'></i></span>
                  </div>
                </div>
                <div class='col-md-3'>
                  %ACCEPT_DIALOGUE_BTN%
                  <div class='balance-buttons mt-2 mb-2 btn-group-vertical %HIDE_CONTROL_BTN%' id='control-btn'
                       style='width: 100%'>
                    <a class='btn btn-default btn-lg' id='send-btn'>_{SEND}_</a>
                    <a class='btn btn-warning btn-lg' id='forward-dialogue'>_{REDIRECT_DIALOGUE}_</a>
                    <a class='btn btn-primary btn-lg' id='close-dialogue'>_{CLOSE_DIALOGUE}_</a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class='col-md-2'>
    <div class='card card-primary card-outline container-md'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{PENDING_APPEALS}_</h4>
      </div>
      <div class='card-body p-0'>
        %NEW%
      </div>
    </div>
    <div class='card card-success card-outline container-md'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{ACTIVE_APPEALS}_</h4>
      </div>
      <div class='card-body p-0'>
        %ACTIVE%
      </div>
    </div>
    <div class='card card-warning card-outline container-md'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{WAITING}_</h4>
      </div>
      <div class='card-body p-0'>
        %WAITING%
      </div>
    </div>
  </div>
</div>

<script>
  var CRM_FILE_TOO_LARGE = '_{CRM_FILE_TOO_LARGE}_' || 'File is too large. Maximum file size';
  var CRM_MAX_FILES_ALLOWED = '_{CRM_MAX_FILES_ALLOWED}_' || 'Maximum number of files allowed';
  var DIALOGUE_ALREADY_ACCEPTED = '_{DIALOGUE_ALREADY_ACCEPTED}_' || 'The dialogue has already been accepted';
  var SIZE = '_{SIZE}_' || 'Size';
</script>
<script src='/styles/default/js/modules/crm/crm.dialogue.js'></script>