<FORM action='$SELF_URL' METHOD=POST>
    <input type=hidden name=index value=$index>
    <input type=hidden name=CID value='%ISG_CID_CUR%'>
    <input type=hidden name=sid value='$sid'>

    <div class='card card-primary card-outline'>
            <div class='form-group row' style="margin:10px;">
                <label class='col-md-3 control-label'>%TP_NAME%: "TURBO _{MODE}_"</label>
                <div class='col-md-7'>
                    %SPEED_SEL%
                </div>
                <input type=submit name=change value='_{ACTIVATE}_'
                class='btn btn-primary'>
            </div>
    </div>
</FORM>