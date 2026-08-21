<div class='row'>
   <div class='col-md-5'>
      <div class='card' style='margin: 15px;'>                                                                                                                                                                                         
      <div class='card-header'>_{PHONE_SPECIAL}_</div>                                                                                                                                                                                   
      <div class='card-body'>
      <form name='SORM_PHONE_SPECIAL' id='' class='form form-horizontal hidden-print form-main' method="POST">
         <input class='form-control' type='hidden' name='index' value='$index'>
         <input type='hidden' name='%ACTION%' value='%ACTION_VALUE%' />
         <input type="hidden" name="phone_special" value="1" />
         <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{PHONE_SPECIAL_DESCRIPTION}_</span>
            <input class='form-control' type='text' name='DESCRIPTION' value='%DESCRIPTION%'>
         </div>
	 <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{PHONE_SPECIAL_NUMBER}_</span>
            <input class='form-control' type='text' name='PHONE_NUMBER' value='%PHONE_NUMBER%'>
         </div>
         <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{PHONE_SPECIAL_IPV4}_</span>
            <input class='form-control' type='text' name='IPV4' value='%IPV4%'>
         </div>
	 <div class='form-group row'>
            <span class='input-group-addon' style='min-width:100px;'>_{PHONE_SPECIAL_IPV6}_</span>
            <input class='form-control' type='text' name='IPV6' value='%IPV6%'>
         </div>
	 <div class='form-group row'>
	    <span class='input-group-addon' style='min-width:100px;'>_{BEGIN_TIME}_</span>
            %BEGIN_TIME%
	 </div>
	 </br>
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
    		_{PHONE_SPECIAL_INFO}_
	    </div>
	</div>
   </div>
</div>
<br>
