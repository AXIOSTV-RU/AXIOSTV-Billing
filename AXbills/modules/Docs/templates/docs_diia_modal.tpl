<form>
  <div class='card-header' style='display: none'>
    <h5 class='card-title'>_{SIGN}_</h5>
  </div>

  <div id='info_alert' class='hidden'>
    <div class='alert alert-info text-left'>
      <h4>
        <span id='info_alert_icon' class='fas fa-check-circle'></span>
        <span id='info_alert_header'>_{INFO}_</span>
      </h4>
      <span id='info_alert_body'>_{INFO}_</span>
    </div>
  </div>
  <div class='spinner-container'>
    <div class='spinner-border text-primary' role='status'>
      <span class='visually-hidden'></span>
    </div>
  </div>
  <div id='register_document' class='hidden'>
    <div>
      <ul class='list-unstyled' id='accordion_branches'></ul>
    </div>
    <input type='button' class='btn btn-primary disabled' disabled value='_{ADD}_' onclick='registerDocument()'>
  </div>
  <div id='delete_document' class='hidden'>
    <input type='button' class='btn btn-danger' value='_{DELETE}_' onclick='deleteDocument()'>
  </div>
</form>

<style>
  #accordion_branches {
    border-top: none;
    margin-bottom: 0;
  }

  .spinner-container {
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .spinner-border {
    height: 60px;
    width: 60px;
  }

  #register_document > .btn {
    float: right;
  }

  #delete_document > .btn {
    float: left;
  }
</style>

<script>

  var edocsDiiaBranches;
  var edocsDiiaBranchesHtml = '';
  var edocId = 0;

  // TODO: make dynamic load of lang keys
  var edocDiiaMessages = {
    ESIGN_SERVICE_NOT_CONNECTED: '_{ESIGN_SERVICE_NOT_CONNECTED}_',
    ESIGN_SERVICE_BAD_CONFIGURATION: '_{ESIGN_SERVICE_BAD_CONFIGURATION}_',
    ERR_DIIA_GET_BRANCHES: '_{ERR_DIIA_GET_BRANCHES}_',
    DOCUMENT_ALREADY_SIGNING: '_{DOCUMENT_ALREADY_SIGNING}_',
    DOCUMENT_SEND_USER_FOR_SIGN: '_{DOCUMENT_SEND_USER_FOR_SIGN}_',
    ERR_NOT_EXISTS: '_{ERR_NOT_EXISTS}_',
    DOCUMENT_SIGNING: '_{DOCUMENT_SIGNING}_',
    DOCUMENT_SIGNED: '_{DOCUMENT_SIGNED}_',
    SUCCESSFULLY_DELETED: '_{SUCCESSFULLY_DELETED}_',
  };

  function deleteDocument () {
    jQuery('#delete_document').addClass('hidden');
    showSpinner(false);
    sendRequest(`/api.cgi/docs/edocs/${edocId}`, {}, 'DELETE').then(res => {
      if (res?.errno) {
        return handleError(res);
      }

      updateAlert(edocDiiaMessages[res?.result] || '_{INFO}_', '', '', 'alert-success');

      showSpinner(false);
    }).catch(e => {
      showSpinner(false);
      console.log(e);
    });
  }

  function registerDocument () {
    jQuery('#register_document').addClass('hidden');
    showSpinner(true);

    const activeRadio = jQuery('input[type=radio]:checked').val();

    const [offerId, branchId] = activeRadio.split(/\|/gm);

    const data = {
      docType: '%DOC_TYPE%' || '--',
      docId: '%DOC_ID%' || '--',
      uid: '%UID%' || 0,
      companyId: '%COMPANY_ID%' || 0,
      offerId: offerId || '',
      branchId: branchId || '',
    };

    sendRequest(`/api.cgi/docs/edocs/`, data, 'POST').then(res => {
      if (res?.errno) {
        return handleError(res);
      }

      let color = 'alert-info';
      if (!res?.warning) {
        color = 'alert-success';
      }

      edocId = res?.id || 0;
      showAlert(true);
      showSpinner(false);
      updateAlert(edocDiiaMessages[res?.result] || '_{INFO}_', '', '', color);
      jQuery('#delete_document').removeClass('hidden');
    }).catch(e => {
      showSpinner(false);
      console.log(e);
    });
  }

  function getBranches () {
    sendRequest(`/api.cgi/docs/edocs/branches/`, {}, 'GET').then(branches => {
      edocsDiiaBranches = branches;
      jQuery('#register_document').removeClass('hidden');

      if (branches?.errno) {
        return handleError(branches);
      }

      let number = 0;
      Object.keys(branches).forEach(branchKey => {
        const branch = branches[branchKey];
        edocsDiiaBranchesHtml += `<li data-toggle='collapse' class='badge-link collapsed' href='#table_${number}'><p>${branch.customfullname || branch.name}</p>
        <p><i class='right fa fa-angle-left'></i></p></li>
      <li id=` + `table_${number}` + ` class='collapse'>
        <div class='card card-default'>
          <div class='card-body table-responsive p-0'>

            <table class='table table-striped table-hover table-condensed'>
              <tbody>`;

        Object.keys(branch?.offers).forEach(offerKey => {
          const offer = branches[branchKey]?.offers[offerKey];
          edocsDiiaBranchesHtml += `<tr>
                <td><input type='radio' name='BRANCH' value='` + offer.id + `|`+ branchKey +`'></td>
                <td>
                  <div>` + offer.name + `</div>
                </td>
              </tr>`
        });

        edocsDiiaBranchesHtml += `</table>
          </div>
        </div>
      </li>`;
        number++;
      });

      showSpinner(false);
      jQuery('#accordion_branches').append(edocsDiiaBranchesHtml);
      handleRadioClick();
    }).catch(e => {
      showSpinner(false);
      console.log(e);
    });
  }

  function checkDocument () {
    const docId = '%DOC_ID%' || '--';
    const docType = '%DOC_TYPE%' || '--';
    const uid = '%UID%' || 0;
    const companyId = '%COMPANY_ID%' || 0;

    sendRequest(`/api.cgi/docs/edocs?docType=${docType}&docId=${docId}&uid=${uid}&companyId=${companyId}`, {}, 'GET').then(res => {
      if (!res.length) {
        getBranches();
        return 1;
      }
      else {
        edocId = res[0]?.id || 0;
        let color = 'alert-info';
        if (!res[0]?.status) {
          color = 'alert-success';
        }
        else {
          jQuery('#delete_document').removeClass('hidden');
        }

        let alertMessage = `${edocDiiaMessages[res[0]?.statusMessage] || '_{INFO}_'}<br/>`
          + `<b>_{DEPARTMENT}_</b>: ${res[0]?.branchInfo?.customfullname || ''}<br/>`
          + `<b>_{TYPE}_</b>: ${res[0]?.offerInfo?.name || ''}<br/>`;

        updateAlert(alertMessage, '', '', color);
        showAlert(true);
      }

      showSpinner(false);
    }).catch(e => {
      showSpinner(false);
      console.log(e);
    });
  }

  function handleError (error) {
    updateAlert(`_{ERROR}_ ${error.errno}`, edocDiiaMessages[error?.errstr] || error?.errstr, 'fa-times-circle', 'alert-danger');
    showAlert(true);
    showSpinner(false);
    return 1;
  }

  function showSpinner (show) {
    if (show) {
      jQuery('.spinner-container').removeClass('d-none');
    }
    else {
      jQuery('.spinner-container').addClass('d-none');
    }
  }

  function showAlert (show) {
    if (show) {
      jQuery('#info_alert').removeClass('hidden');
    }
    else {
      jQuery('#info_alert').addClass('hidden');
    }
  }

  function updateAlert (header, message, icon, color) {
    if (message) {
      jQuery('#info_alert_header').html(message);
    }
    if (header) {
      jQuery('#info_alert_body').html(header);
    }
    if (icon) {
      jQuery("#info_alert_icon").removeClass().addClass('fas {icon}');
    }
    if (color) {
      jQuery("#info_alert div").removeClass().addClass(`alert ${color} text-left`);
    }
  }

  function handleRadioClick () {
    jQuery(document).ready(() => {
      jQuery('input[type=radio]').on('click', () => {
        const checked = jQuery('input[type=radio]:checked');
        if (checked.length) {
          jQuery('#register_document .btn').removeClass('disabled').removeAttr('disabled');
        }
      });
    });
  }

  checkDocument();

  jQuery('#accordion_open_all').on('click', function () {
    jQuery('#accordion .collapse').collapse('toggle');
  });
</script>
