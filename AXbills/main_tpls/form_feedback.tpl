<form name='FEEDBACK' id='form_FEEDBACK' class='form form-horizontal'
      action='https://support.billing.axiostv.ru/secure/CreateIssueDetails!init.jspa?' target='_blank'
      method='post' >
   <input type=hidden name='reporter' value='%HELP_DESK_LOGIN%'>
   <input type=hidden name='pid' value='%pid%'>
   <input type=hidden name='issuetype' value='%issuetype%'>
   <input type=hidden name='summary' value='_{error_in}_ %function_name%'>
   <input type=hidden name='description' value='_{help_error_text}_ \n =============== \n \n %@ \n =============== \n _{bil_vers}_ %version% \n _{bil_funct_name}_ %function_name% \n \n'>
  <div class='form-group row'>
    <label class='control-label col-md-3' for='COMMENTS_ID'>_{YOUR_FEEDBACK}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' rows='5' name='ERROR' id='COMMENTS_ID'>%COMMENTS%</textarea>
    </div>
  </div>

  <div class='form-group text-center'>
    <input id='go' type='submit' form='form_FEEDBACK' class='btn btn-primary' name='add' value='_{SEND}_'>
  </div>

</form>
