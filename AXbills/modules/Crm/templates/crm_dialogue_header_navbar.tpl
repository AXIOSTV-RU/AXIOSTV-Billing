<li class='nav-item dropdown' id='dialogues-menu' data-meta='{
          "HEADER": "_{DIALOGUES}_",
          "UPDATE": "%UPDATE%",
          "AFTER": 3,"REFRESH": 30, "BADGE": "%BADGE%"
          }'>

  <a href='#' class='nav-link dropdown-toggle' data-toggle='dropdown' title='_{DIALOGUES}_'>
    <i class='far fa-comments'></i>
    <span id='badge_dialogues-menu' class='icon-label label label-danger hidden'></span>
  </a>

  <div class='dropdown-menu dropdown-menu-lg dropdown-menu-right' id='dropdown_dialogues-menu'>
        <span class='dropdown-item dropdown-header' id='header_dialogues-menu'>
          <h6 class='header_text float-left pt-1'></h6>
            <div class='text-right'>
              <div class='btn-group'>
                <button class='btn btn-sm btn-success header_refresh'>
                  <i class='fas fa-sync' role='button'></i>
                </button>
              </div>
            </div>
        </span>

    <div class='dropdown-divider'></div>
    <div class='dropdown-items-list' id='menu_dialogues-menu'>
      <div class='text-center'>
        <i class='fa fa-spinner fa-pulse fa-2x'></i>
      </div>
    </div>

    <div class='dropdown-divider'></div>
    <a id='footer_events-menu' class='dropdown-item dropdown-footer' href='%SELF_URL%?get_index=crm_dialogues&full=1'>_{SHOW}_ _{ALL}_</a>
  </div>
</li>