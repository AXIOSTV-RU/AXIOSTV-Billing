<form method='post' id='docs_diia_branches'>
  <input type=hidden name='index' value=%index%>
  <input type=hidden name='ID' value=%ID%>
  <input type=hidden name='BRANCH' value=%BRANCH%>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{ARTICLE}_ _{ADD}_</h4>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label required' for='NAME'>_{NAME}_ _{ARTICLE}_:</label>
        <div class='col-md-9'>
          <input class='form-control' required type=text id='NAME' name='NAME' value='%NAME%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label' for='RETURN_LINK'>_{RETURN_LINK}_</label>
        <div class='col-md-9'>
          <input class='form-control' type=text id='RETURN_LINK' name='RETURN_LINK' value='%RETURN_LINK%'>
        </div>
      </div>
    </div>

    <div class='col-md-12'>
      <div class='card-footer'>
        <input class='btn btn-primary' type='submit' name='%ACTION%' value='%LNG_ACTION%'>
      </div>
    </div>
  </div>
</form>
