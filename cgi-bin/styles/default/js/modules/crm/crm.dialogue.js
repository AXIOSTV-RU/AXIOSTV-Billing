let start_date = formatDate(new Date(), 'yyyy-mm-dd hh:ii:ss');
let end_date = start_date;
let last_message_from_aid = jQuery('#LAST_MESSAGE_FROM_AID').val();

jQuery(document).ready(function () {
  const fileUploader = new FileUploader('/api.cgi/crm/attachment', 'fileInput', 'fileListContainer');
  fileUploader.apiDownloadUrl = '/api.cgi/crm/attachment/:fileId/content/';

  jQuery('.crm-attachment').on('click', function (){
    fileUploader.downloadFile(jQuery(this).data('id'), jQuery(this).text());
  });

  scrollToBottom();

  jQuery('#accept-dialogue').on('click', function () {
    let self = this;
    sendRequest(`/api.cgi/crm/dialogue/${jQuery('#DIALOGUE_ID').val()}`, {aid: jQuery('#AID').val()}, 'PUT')
      .then((data) => {
        if (data.affected) {
          jQuery(self).hide()
          jQuery('#control-btn').removeClass('d-none');
          jQuery('#message-textarea').removeAttr('disabled');
        } else {
          jQuery(self).addClass('disabled').text(DIALOGUE_ALREADY_ACCEPTED);
        }
      });
  });

  jQuery('#close-dialogue').on('click', function () {
    jQuery('#message-textarea').attr('disabled', 'disabled');
    sendRequest(`/api.cgi/crm/dialogue/${jQuery('#DIALOGUE_ID').val()}`, {state: 1}, 'PUT')
      .then((data) => {
        jQuery('#control-btn').remove();
      });
  });

  jQuery('#send-btn').on('click', function () {
    let message = jQuery('#message-textarea').val();

    let files = fileUploader.getUploadedFiles();
    if (!message && Object.keys(files).length < 1) return;
    jQuery('#message-textarea').val('');

    let lastReply = addReply({ message: message, aid: jQuery('#AID').val(), attachments: files });
    let replyTime = jQuery(lastReply).find('.reply-time').first();
    sendRequest(`/api.cgi/crm/dialogue/${jQuery('#DIALOGUE_ID').val()}/message`,
      {message: message, attachmentId: Object.keys(files)})
      .then((data) => {
        replyTime.html('');
        const now = new Date();

        if (data?.errno || !data?.insertId) {
          let errorInfo = jQuery(`<i class='fa fa-info-circle mr-1 cursor-pointer'></i>`);
          if (data?.errstr) {
            renderTooltip(errorInfo, data.errstr, 'top');
          }

          replyTime.append(errorInfo);
          let minutes = now.getMinutes();
          replyTime.append(message.time || (now.getHours() + ':' + (minutes < 10 ? `0${minutes}` : minutes)));
          replyTime.removeClass('text-muted').addClass('text-danger');
          // lastReply.remove();
          // if (files) {
          //   Objects.keys(files).forEach(fileId => {
          //     console.log(fileId);
          //   });
          // }
        }
        else {
          let minutes = now.getMinutes();
          replyTime.append(message.time || (now.getHours() + ':' + (minutes < 10 ? `0${minutes}` : minutes)));
        }
      })
      .catch(e => {
        const now = new Date();
        let errorInfo = jQuery(`<i class='fa fa-info-circle mr-1 cursor-pointer'></i>`);
        if (e) {
          renderTooltip(errorInfo, e, 'top');
        }

        replyTime.append(errorInfo);
        let minutes = now.getMinutes();
        replyTime.append(message.time || (now.getHours() + ':' + minutes < 10 ? `0${minutes}` : minutes));
        replyTime.removeClass('text-muted').addClass('text-danger');
      })
      .finally(() => {
        fileUploader.resetUploadedFiles();
      });
    jQuery('#fileListContainer').html('');

  });

  jQuery('#forward-dialogue').on('click', function () {
    jQuery('#control-btn').addClass('d-none');
    jQuery('#message-textarea').attr('disabled', 'disabled');
    sendRequest(`/api.cgi/crm/dialogue/${jQuery('#DIALOGUE_ID').val()}`, {aid: '0'}, 'PUT')
      .then((data) => {
        location.reload();
      });
  });

  setInterval(function () {
    end_date = formatDate(new Date(), 'yyyy-mm-dd hh:ii:ss');
    sendRequest(`/api.cgi/crm/dialogue/${jQuery('#DIALOGUE_ID').val()}/messages?AID=0&AVATAR_LINK=_SHOW&FROM_DATE=${start_date}&TO_DATE=${end_date}`, {}, 'GET')
      .then(data => {
        if (!Array.isArray(data)) return;
        if (data.length > 0) start_date = end_date;

        data.forEach(function (message) {
          createMessage(message);
          scrollToBottom();
        });
      });
  }, 10000);


  function createMessage(message) {
    if (jQuery('.hr-lines').last().text() !== message.day) {
      let date_line = document.createElement('h6');
      date_line.classList.add('hr-lines', 'text-muted');
      date_line.innerText = message.day;
      document.getElementById('msg_block').appendChild(date_line);
      last_message_from_aid = undefined;
    }

    message.aid = 0;
    message.avatarLink = message.avatarLink ? `/images/${message.avatarLink}` : jQuery('#USER_AVATAR_LINK').val();
    addReply(message)
  }

  async function sendRequest(url = '', data = {}, method = 'POST') {
    const response = await fetch(url, {
      method: method,
      mode: 'cors',
      cache: 'no-cache',
      credentials: 'same-origin',
      headers: {'Content-Type': 'application/json'},
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
      body: method === 'GET' ? undefined : JSON.stringify(data)
    });
    return response.json();
  }

  function addReply(message) {
    let aid = message.aid || 0;
    let reply_class = aid ? 'justify-content-end' : 'justify-content-start';
    let main = document.createElement('div');
    main.classList.add(reply_class, 'd-flex', 'mb-3');

    let img = document.createElement('img');
    img.src = message.avatarLink ? message.avatarLink :
      aid ? jQuery('#ADMIN_AVATAR_LINK').val() : jQuery('#USER_AVATAR_LINK').val();
    img.classList.add('rounded-circle', 'user_img_msg');
    let avatar = document.createElement('div');
    avatar.classList.add('img_cont_msg');
    if (aid != last_message_from_aid) avatar.appendChild(img);

    let message_block = document.createElement('div');
    message_block.classList.add('message');
    message_block.innerText = message.message;
    if (message.attachments) {
      let attachmentBlock = formAttachments(message.attachments);
      if (attachmentBlock) message_block.appendChild(attachmentBlock);
    }

    let time = document.createElement('span');
    time.classList.add('text-muted', 'float-right', 'ml-1', 'reply-time');
    // const now = new Date();
    // time.innerText = message.time || (now.getHours() + ':' + now.getMinutes());
    let spin = document.createElement('i');
    spin.classList.add('fa', 'fa-spinner', 'fa-pulse');
    time.appendChild(spin)
    message_block.appendChild(time);

    main.appendChild(message_block);
    aid ? main.appendChild(avatar) : main.prepend(avatar);

    setTimeout(function () {
      let messages = document.getElementById('msg_block');
      messages.appendChild(main);
      scrollToBottom();
    }, 300);
    last_message_from_aid = aid;
    return main;
  }

  function formAttachments(files) {
    let result = document.createElement('div');
    let imageRegExp = /^image\//;

    for (const [id, file] of Object.entries(files)) {
      let fileId = file.id || id;
      if (!fileId || !file.name) next;

      let fileHref = document.createElement('a');
      fileHref.innerText = file.name;
      fileHref.classList.add('crm-attachment', 'cursor-pointer');
      let fileSize = document.createElement('span');
      fileSize.classList.add('ml-1');
      fileSize.innerText = `(${SIZE}: ${formatBytes(file.size)})`;
      let hr = document.createElement('hr');
      hr.classList.add('m-1');

      fileHref.addEventListener('click', () => {
        fileUploader.downloadFile(fileId, file.name);
      });


      if (imageRegExp.test(file.type)) {
        let img = document.createElement('img');
        img.src = `/images/attach/crm/${file.name}`;
        img.classList.add('d-block', 'img-fluid', 'modal-content-img', 'dialogue-attachment');
        result.appendChild(img);
      }

      result.appendChild(hr);
      result.appendChild(fileHref);
      result.appendChild(fileSize);
    }

    return result.children.length > 0 ? result : undefined;
  }
});

function formatDate(date, format) {
  const leadingZero = (num) => `0${num}`.slice(-2);
  const map = {
    mm: leadingZero(date.getMonth() + 1),
    dd: leadingZero(date.getDate()),
    yyyy: date.getFullYear(),
    hh: leadingZero(date.getHours()),
    ii: leadingZero(date.getMinutes()),
    ss: leadingZero(date.getSeconds()),
  }

  return format.replace(/mm|dd|yyyy|hh|ii|ss/gi, matched => map[matched])
}

function scrollToBottom() {
  let messages = document.getElementById('msg_block');
  messages.scrollTop = messages.scrollHeight;
}