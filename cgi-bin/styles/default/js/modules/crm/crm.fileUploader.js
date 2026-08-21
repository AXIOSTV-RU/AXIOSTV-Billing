class FileUploader {
  constructor(apiUrl, fileInputId, fileListContainerId) {
    this.apiUrl = apiUrl;
    this.fileBtn = document.getElementById(fileInputId);
    this.fileInput = null;
    this.fileListContainer = document.getElementById(fileListContainerId);
    this.uploadedFiles = {};
    this.apiDownloadUrl = undefined;

    this.fileBtn.addEventListener('click', () => {
      this.fileInput = document.createElement('input');
      this.fileInput.type = 'file';
      this.fileInput.classList.add('hidden');
      this.fileInput.addEventListener('change', this.handleFileSelect.bind(this));
      this.fileInput.click();
    });
    this.maxSizeMB = 20;
    this.maxFiles = 5;
  }

  handleFileSelect(event) {
    const files = event.target.files;

    for (const file of files) {
      this.uploadFile(file);
    }

    this.fileInput = null;
  }

  getUploadedFiles() {
    return this.uploadedFiles;
  }

  resetUploadedFiles() {
    this.uploadedFiles = [];
  }

  uploadFile(file) {
    const xhr = new XMLHttpRequest();
    const formData = new FormData();
    formData.append('file', file);

    if (this.maxFiles <= Object.keys(this.uploadedFiles).length) {
      alert(`${CRM_MAX_FILES_ALLOWED}: ${this.maxFiles}`);
      return;
    }

    const maxSizeBytes = this.maxSizeMB * 1024 * 1024;
    if (!file.size) return;
    if (file.size > maxSizeBytes) {
      alert(`${CRM_FILE_TOO_LARGE}: ${this.maxSizeMB}MB`);
      return;
    }

    let newFileContainer = this.createFileContainer(file, xhr);
    let progressBar = newFileContainer.querySelector('progress')
    let removeButton = newFileContainer.querySelector('button.close')
    this.fileListContainer.appendChild(newFileContainer);

    removeButton.addEventListener('click', () => {
      xhr.abort();
      removeButton.disabled = true;
      newFileContainer.remove();
    });

    xhr.upload.addEventListener('progress', (event) => {
      if (event.lengthComputable) {
        progressBar.value = (event.loaded / event.total) * 100;
      }
    });

    xhr.onreadystatechange = () => {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        progressBar.remove();

        const status = xhr.status;
        if (status === 0 || (status >= 200 && status < 400)) {
          let data;
          try {
            data = JSON.parse(xhr.responseText);
          }
          catch (e) {
            console.log(e)
          }

          if (data && typeof data === 'object' && data.insertId && !data.errno) {

            this.uploadedFiles[data.insertId] = { name : data.filename || file.name, size: file.size, type: file.type };
            removeButton.addEventListener('click', () => {
              removeButton.disabled = true;
              newFileContainer.remove();

              delete this.uploadedFiles[data.insertId];
              this.deleteFile(data.insertId);
            });
          }
        } else {

        }
      }
    };

    xhr.open('POST', this.apiUrl, true);
    xhr.send(formData);
  }

  downloadFile(fileId, fileName) {
    if (!this.apiDownloadUrl || !fileId || !fileName) return;

    let url = this.apiDownloadUrl.replace(':fileId', fileId);
    const xhr = new XMLHttpRequest();
    xhr.open('GET', url, true);
    xhr.responseType = 'blob';

    xhr.onload = () => {
      if (xhr.status === 200) {
        let a = document.createElement('a');
        let url = window.URL.createObjectURL(xhr.response);
        a.href = url;
        a.download = fileName;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
      }
    };
    xhr.onerror = function () {
      console.error('Error downloading the file.');
    };
    xhr.send();
  }

  createFileContainer(file) {
    if (!file || !file.name) return '';
    const [name, extension] = file.name.split('.');

    const div = document.createElement('div');
    div.className = 'd-flex flex-row flex-nowrap mb-2';

    const textDiv = this.createFileUploadInfoElement('pl-1 pr-0 pt-1 pb-1 text-truncate', name);
    const extensionDiv = this.createFileUploadInfoElement('pl-0 pr-1 pt-1 pb-1', `.${extension}`);
    const sizeDiv = this.createFileUploadInfoElement('p-1 text-nowrap', formatBytes(file.size));

    const progressDiv = this.createFileUploadInfoElement('pt-2 pl-1 pr-1');
    const progress = document.createElement('progress');
    progress.id = 'file';
    progress.max = 100;
    progress.value = 0;
    progress.textContent = '0%';
    progressDiv.appendChild(progress);

    const removeButtonDiv = this.createFileUploadInfoElement('pl-1');
    const removeButton = document.createElement('button');
    removeButton.type = 'button';
    removeButton.className = 'close mt-1 pr-2';
    removeButton.innerHTML = '<span aria-hidden="true">×</span>';
    removeButtonDiv.appendChild(removeButton);

    div.appendChild(textDiv);
    div.appendChild(extensionDiv);
    div.appendChild(sizeDiv);
    div.appendChild(progressDiv);
    div.appendChild(removeButtonDiv);

    return div;
  }

  createFileUploadInfoElement(className, text) {
    const div = document.createElement('div');
    div.className = `file-upload-info ${className}`;
    div.textContent = text;
    return div;
  }

  deleteFile(fileId) {
    this.removeFileFromServer(fileId);
  }

  removeFileFromServer(fileId) {
    fetch(`${this.apiUrl}/${fileId}`, {
      method: 'DELETE',
    })
      .then(response => {
        if (!response.ok) {
          throw new Error('File deletion failed');
        }
        return response.json();
      })
      .then(data => {
        // console.log('File deleted successfully:', data);
      })
      .catch(error => {
        // console.error('File deletion failed:', error);
      });
  }
}