/**
 * Created by Yusk on 03.10.2022
 *
 *   Make electronic sign of document by user
 *
 */

'use strict';

jQuery(document).ready(() => {
  jQuery('.esign_user_button').on('click', async function() {

    const res = await sendRequest(`/api.cgi/user/docs/edocs/sign/${jQuery(this).attr('value')}/`,
      {}, 'POST', {
      USERSID: window['SID']
    });

    if (res?.errno || res?.error) {
      loadDataToModal(`ERROR - ${res?.errno || res?.error}`, true);
      return 1;
    }

    if (!res?.url) {
      loadDataToModal(`NOT_SUPPORTED`, true);
      console.log('NOT_SUPPORTED');
      return 1;
    }

    // await sendRequest(`/api.cgi/user/`, {
    //   userAgent: navigator.userAgent,
    // }, 'POST');

    if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || 'ontouchstart' in window) {
      window.location.replace(res?.url);
    } else {
      showImgInModal(`${window['BASE_URL']}?qrcode=1&qindex=10010&QRCODE_URL=${res?.url}`, SCAN_QR_CODE_IN_DIIA_APP);
    }
  });

  jQuery('.esign_user_download').on('click', async function() {

  });
});
