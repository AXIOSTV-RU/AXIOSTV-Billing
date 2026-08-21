<div class='row'>
   <div class='col-md-5'>
   <div class='card' style='margin: 15px;'>
      <div class='card-header'>_{GATEWAYS}_</div>
      <div class='card-body'>
      <form name='SORM_GATEWAY' id='' class='form form-horizontal hidden-print form-main' method="POST">
         <input class='form-control' type='hidden' name='index' value='$index'>
         <input type='hidden' name='%ACTION%' value='%ACTION_VALUE%' />
         <input type="hidden" name="gateways" value="1" />
         <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{GATE_NAME}_</span>
            <input class='form-control' type='text' name='DESCRIPTION' value='%DESCRIPTION%'>
         </div>
         <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{GATE_TYPE}_</span>
            %GATE_TYPE%
         </div>
         <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{IPV4_GATE_DESCRIPTION}_</span>
            <input class='form-control' type='text' name='IPV4' value='%IPV4%'>
         </div>
	 <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{IPV6_GATE_DESCRIPTION}_</span>
            <input class='form-control' type='text' name='IPV6' value='%IPV6%'>
         </div>
         <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{CITY}_</span>
            <input class='form-control' type='text' name='CITY' value='%CITY%'>
         </div>
         <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{STREET}_</span>
            <input class='form-control' type='text' name='STREET' value='%STREET%'>
         </div>
         <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{BUILD}_</span>
            <input class='form-control' type='text' name='BUILDING' value='%BUILDING%'>
         </div>
         <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{FLAT}_</span>
            <input class='form-control' type='text' name='APARTMENT' value='%APARTMENT%'>
         </div>
	  <div class='form-group row'>
	    <span class='input-group-addon' style='min-width:100px;'>_{BEGIN_TIME}_</span>
            %BEGIN_TIME%
	 </div>
         <br>
         <!-- <div class='col-md-4' style='float: left;'>
            <input type='checkbox' name='DISABLED' value='%DISABLED%' />
            <span>Отключенно</span>
         </div> -->
         <div class="col-md-4" style="text-align: left;">
            <button class='btn btn-sm btn-info' type='submit' name='send' value='1'>%ACTION_BUTTON%</button>
         </div>
      </form>
      </div>
   </div>
   </div>
   <div class='col-md-6' style='margin: 15px;'>
	<div class='card'>
	<div class='card-body'>
	    _{GATEWAYS_INFO}_
	</div>
	</div>
   </div>
</div>
<br>
