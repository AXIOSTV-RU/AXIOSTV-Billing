<form method='post' id='docs_diia_branches'>
  <input type=hidden name='index' value=%index%>
  <input type=hidden name='ID' value=%ID%>

    <div class='card card-primary card-outline'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{DEPARTMENT}_ _{ADD}_</h4>
      </div>

      <div class='card-body'>
        <div class='form-group row'>
          <label class='col-md-3 control-label required' for='NAME'>_{DEPARTMENT_NAME}_:</label>
          <div class='col-md-9'>
            <input class='form-control' required type=text id='NAME' name='NAME' value='%NAME%'>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label required' for='CUSTOM_FULL_NAME'>_{FULL_DEPARTMENT_NAME}_:</label>
          <div class='col-md-9'>
            <input class='form-control' required type=text id='CUSTOM_FULL_NAME' name='CUSTOM_FULL_NAME' value='%CUSTOM_FULL_NAME%'>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label required' for='CUSTOM_FULL_ADDRESS'>_{FULL_DEPARTMENT_ADDR}_:</label>
          <div class='col-md-9'>
            <input class='form-control' required type=text id='CUSTOM_FULL_ADDRESS' name='CUSTOM_FULL_ADDRESS' value='%CUSTOM_FULL_ADDRESS%'>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label' for='EMAIL'>Email:</label>
          <div class='col-md-9'>
            <input class='form-control' type=text id='EMAIL' name='EMAIL' value='%EMAIL%'>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label' for='REGION'>_{REGION}_</label>
          <div class='col-md-9'>
            <input class='form-control' type=text id='REGION' name='REGION' value='%REGION%'>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label' for='DISTRICT'>_{DISTRICT}_</label>
          <div class='col-md-9'>
            <input class='form-control' type=text id='DISTRICT' name='DISTRICT' value='%DISTRICT%'>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label required' for='LOCATION'>_{CITY}_</label>
          <div class='col-md-9'>
            <input class='form-control' required type=text id='LOCATION' name='LOCATION' value='%LOCATION%'>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label required' for='STREET'>_{STREET}_</label>
          <div class='col-md-9'>
            <input class='form-control' required type=text id='STREET' name='STREET' value='%STREET%'>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label required' for='HOUSE'>_{BUILD}_</label>
          <div class='col-md-9'>
            <input class='form-control' required type=text id='HOUSE' name='HOUSE' value='%HOUSE%'>
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
