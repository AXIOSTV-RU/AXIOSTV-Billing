<form action='%SELF_URL%' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'>

  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='UID' value='%UID%'>

  <div class='%FORM_ATTR%'>
    %MAIN_USER_TPL%
  </div>
  <div id='form_2' class='card for_sort card-primary card-outline %FORM_ATTR%'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{INFO}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='card-body'>
      <div class='form-group row' id='simple_fio'>
        <label class='col-sm-3 col-md-2 text-right control-label %FIO_REQ%' for='FIO'>_{FIO}_:</label>
        <div class='col-sm-9 col-md-10'>
          <div class='input-group'>
            <input name='FIO' class='form-control' %FIO_REQ% %FIO_READONLY% id='FIO' value='%FIO%'>
            <div class='input-group-append'>
              <button id='show_fio' type='button' class='btn btn-default' tabindex='-1'>
                <i class='fa fa-bars'></i>
              </button>
            </div>
          </div>
        </div>
      </div>

      <div id='full_fio' style='display:none'>
        <div class='form-group row'>
          <label class='col-form-label text-md-right col-md-4' for='FIO1'>_{FIO1}_:</label>
          <div class='col-sm-8 col-md-8'>
            <div class='input-group'>
              <input name='FIO1' class='form-control' id='FIO1' value='%FIO1%'>
              <div class='input-group-append'>
                <button id='hide_fio' type='button' class='btn btn-default' tabindex='-1'>
                  <i class='fa fa-reply'></i>
                </button>
              </div>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-form-label text-md-right col-md-4' for='FIO2'>_{FIO2}_:</label>
          <div class='col-sm-8 col-md-8'>
            <div class='input-group'>
              <input name='FIO2' class='form-control' id='FIO2' value='%FIO2%'>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-form-label text-md-right col-md-4' for='FIO3'>_{FIO3}_:</label>
          <div class='col-sm-8 col-md-8'>
            <div class='input-group'>
              <input name='FIO3' class='form-control' id='FIO3' value='%FIO3%'>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='IS_COMPANY'>Это компания</label>
        <div class='col-sm-8 col-md-8 form-check d-flex align-items-center'>
          <input id='IS_COMPANY' name='IS_COMPANY' value='1' type='checkbox' class='form-check-input' %IS_COMPANY_CHECKED%>
        </div>
      </div>

      <div class='form-group row' id='company_name_row' style='%COMPANY_NAME_DISPLAY%'>
        <label class='col-form-label text-md-right col-md-4' for='COMPANY_NAME'>_{COMPANY}_:</label>
        <div class='col-sm-8 col-md-8'>
          <div class='input-group'>
            <input name='COMPANY_NAME' class='form-control' id='COMPANY_NAME' value='%COMPANY_NAME%'>
          </div>
        </div>
      </div>

      <div class='card card-outline card-big-form collapsed-card mb-0 border-top' id='company_data_row' style='%COMPANY_NAME_DISPLAY%'>
        <div class='card-header'>
          <h3 class='card-title'>_{COMPANY_DATA_FULL}_</h3>
          <div class='card-tools'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>

        <div class='card-body'>
          <div class='card-header'>
            <h3 class='card-title'>_{COMPANY_DATA}_</h3>
          </div>

          <div class='form-group row'>
            <label for='INN' class='control-label col-md-3'>_{TAX_NUMBER}_:</label>
            <div class='input-group col-md-9'>
              <input class='form-control' id='INN' name='INN' value='%INN%'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='KPP' class='control-label col-md-3'>_{KPP}_:</label>
            <div class='input-group col-md-9'>
              <input class='form-control' id='KPP' name='KPP' value='%KPP%'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='OGRN' class='control-label col-md-3'>_{OGRN}_:</label>
            <div class='input-group col-md-9'>
              <input class='form-control' id='OGRN' name='OGRN' value='%OGRN%'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='OKPO' class='control-label col-md-3'>_{OKPO}_:</label>
            <div class='input-group col-md-9'>
              <input class='form-control' id='OKPO' name='OKPO' value='%OKPO%'>
            </div>
          </div>

          <div class='card-header'>
            <h3 class='card-title'>_{COMPANY_BANK}_</h3>
          </div>

          <div class='form-group row'>
            <label for='BANK_BIC' class='control-label col-md-3'>_{BANK_BIC}_:</label>
            <div class='input-group col-md-9'>
              <input class='form-control' id='BANK_BIC' name='BANK_BIC' value='%BANK_BIC%'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='BANK_NAME' class='control-label col-md-3'>_{BANK}_:</label>
            <div class='input-group col-md-9'>
              <input class='form-control' id='BANK_NAME' name='BANK_NAME' value='%BANK_NAME%'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='BANK_ACCOUNT' class='control-label col-md-3'>_{ACCOUNT}_:</label>
            <div class='input-group col-md-9'>
              <input class='form-control' id='BANK_ACCOUNT' name='BANK_ACCOUNT' value='%BANK_ACCOUNT%'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='COR_BANK_ACCOUNT' class='control-label col-md-3'>_{COR_BANK_ACCOUNT}_:</label>
            <div class='input-group col-md-9'>
              <input class='form-control' id='COR_BANK_ACCOUNT' name='COR_BANK_ACCOUNT' value='%COR_BANK_ACCOUNT%'>
            </div>
          </div>
        </div>
      </div>
    </div>

    %CONTACTS%
    %ADDRESS_TPL%

    <div class='card card-outline card-big-form collapsed-card mb-0 border-top'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{PASPORT}_ / _{OTHER_PASSPORT}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-plus'></i>
          </button>
        </div>
      </div>

      <div class='card-body'>

        <div hidden class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='CITIZENSHIP'>_{CITIZENSHIP}_:</label>
          <div class='col-sm-9 col-md-10'>
            <div class='input-group'>
              <input id='CITIZENSHIP' name='CITIZENSHIP' value='%CITIZENSHIP%' readonly class='form-control' type='text'>
            </div>
          </div>
        </div>

     <div class='form-group row'>
       <label class='col-md-2 col-xs-4 col-form-label text-md-right' for='citizenship_checkbox'>_{CITIZEN}_:</label>
       <div class='col-md-4 col-xs-8 form-check d-flex align-items-center'>
         <div class='input-group'>
           <input id='citizenship_checkbox' type='checkbox' %CITIZENSHIP_CHECKBOX_CHECKED%>
         </div>
       </div>
     </div>

  <div class='form-group row'>
    <label class='col-sm-3 col-md-2 control-label' for='PASPORT_SERIES'>_{PASPORT_SERIES}_:</label>
    <div class='col-sm-9 col-md-4'>
      <div class='input-group'>
        <input id='PASPORT_SERIES' name='PASPORT_SERIES' value='%PASPORT_SERIES%'
              placeholder='XXXX'
              class='form-control' type='text' pattern='\d{4}' title='Введите серию в формате XXXX'>
      </div>
    </div>
    <label class='col-sm-3 col-md-2 control-label' for='PASPORT_NUMBER'>_{PASPORT_NUMBER}_:</label>
    <div class='col-sm-9 col-md-4'>
      <div class='input-group'>
        <input id='PASPORT_NUMBER' name='PASPORT_NUMBER' value='%PASPORT_NUMBER%'
              placeholder='XXXXXX'
              class='form-control' type='text' pattern='\d{6}' title='Введите номер в формате XXXXXX'>
      </div>
    </div>
  </div>

        <!-- Поле полного номера паспорта -->
        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='PASPORT_NUM'>_{PASPORT_NUM}_:</label>
          <div class='col-sm-9 col-md-10'>
            <div class='input-group'>
              <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%' readonly class='form-control' type='text'>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='PASPORT_CODE'>_{PASPORT_CODE}_:</label>
          <div class='col-sm-9 col-md-4'>
            <div class='input-group'>
              <input id='PASPORT_CODE' name='PASPORT_CODE' value='%PASPORT_CODE%'
                     placeholder='XXX-XXX'
                     class='form-control' type='text' pattern='\d{3}-\d{3}' title='Введите код подразделения в формате XXX-XXX'>
            </div>
          </div>
          <label class='col-sm-3 col-md-2 control-label' for='PASPORT_DATE'>_{PASPORT_DATE}_:</label>
          <div class='col-sm-9 col-md-4'>
            <div class='input-group'>
              <input id='PASPORT_DATE' type='text' name='PASPORT_DATE' value='%PASPORT_DATE%'
                class='datepicker form-control'>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='PASPORT_GRANT'>_{GRANT}_:</label>
          <div class='col-sm-9 col-md-10'>
            <div class='input-group'>
              <textarea class='form-control' id='PASPORT_GRANT' name='PASPORT_GRANT' rows='2'>%PASPORT_GRANT%</textarea>
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='BIRTH_DATE'>_{BIRTH_DATE}_:</label>
          <div class='col-sm-9 col-md-4'>
            <div class='input-group'>
              <input class='form-control datepicker' id='BIRTH_DATE' name='BIRTH_DATE'
                type='text' value='%BIRTH_DATE%'>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='PLACE_OF_BIRTH'>_{PLACE_OF_BIRTH}_:</label>
          <div class='col-sm-9 col-md-10'>
            <div class='input-group'>
              <textarea class='form-control' id='PLACE_OF_BIRTH' name='PLACE_OF_BIRTH' rows='2'>%PLACE_OF_BIRTH%</textarea>
            </div>
          </div>
        </div>


        <div class='form-group row'>
          <label class='col-sm-3 col-md-2 control-label' for='REG_ADDRESS'>_{REG_ADDRESS}_:</label>
          <div class='col-sm-9 col-md-10'>
            <div class='input-group'>
              <textarea class='form-control' id='REG_ADDRESS' name='REG_ADDRESS' rows='2'>%REG_ADDRESS%</textarea>
            </div>
          </div>
        </div>
      </div>
    </div>

    %DOCS_TEMPLATE%

    <!-- Other panel  -->
    <div class='card card-outline card-big-form collapsed-card mb-0 border-top'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{EXTRA_ABBR}_. _{FIELDS}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        %INFO_FIELDS%
      </div>
    </div>

    <div class='form-group row mt-3 mr-3 ml-3'>
      <div class='input-group'>
        <textarea class='form-control' id='COMMENTS' placeholder='_{COMMENTS}_' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary double_click_check hidden_empty_required_filed_check' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>

</form>

<script type='text/javascript'>
  document.addEventListener('DOMContentLoaded', function() {
    const seriesInput = document.getElementById('PASPORT_SERIES');
    const numberInput = document.getElementById('PASPORT_NUMBER');
    const passportFullInput = document.getElementById('PASPORT_NUM');
    const codeInput = document.getElementById('PASPORT_CODE');
    const fioInput = document.getElementById('FIO');
    const fio1Input = document.getElementById('FIO1');
    const fio2Input = document.getElementById('FIO2');
    const fio3Input = document.getElementById('FIO3');
    const citizenshipCheckbox = document.getElementById('citizenship_checkbox');
    const citizenshipInput = document.getElementById('CITIZENSHIP');
    const isCompanyCheckbox = document.getElementById('IS_COMPANY');
    const companyNameRow = document.getElementById('company_name_row');
    const companyDataRow = document.getElementById('company_data_row');

// Установка значения по умолчанию для поля CITIZENSHIP
    if (citizenshipInput.value === '') {
      citizenshipInput.value = '1';
      citizenshipCheckbox.checked = true;
    }

// Функция для обновления полного номера паспорта
    function updateFullPassport() {
      const series = seriesInput.value;
      const number = numberInput.value;
      passportFullInput.value = series + ' ' + number;
    }

// Функция для разделения полного номера паспорта
    function splitFullPassport() {
     const fullNumber = passportFullInput.value.replace(/\s/g, '');

// Заполнение полей серии и номера
    if (/[а-яА-Яa-zA-Z]/.test(fullNumber[0])) {
     const seriesMatch = fullNumber.match(/[а-яА-Яa-zA-Z]+/);
     const numberMatch = fullNumber.match(/\d+/g);
    if (seriesMatch && numberMatch) {
     seriesInput.value = seriesMatch[0];
     numberInput.value = numberMatch.join('');
     }
    } else if (fullNumber.length ===10) {
     seriesInput.value = fullNumber.slice(0,4);
     numberInput.value = fullNumber.slice(4);
     }
// Обновление поля полного номера паспорта
    passportFullInput.value = seriesInput.value + ' ' + numberInput.value;
     }

// Функция для разделения ФИО на три части
    function splitFIO() {
      const fio = fioInput.value.trim();
      const parts = fio.split(/\s+/); // Разделяем по пробелам

      fio1Input.value = parts[0] || ''; // Фамилия
      fio2Input.value = parts[1] || ''; // Имя
      fio3Input.value = parts.slice(2).join(' ') || ''; // Остаток (Отчество или другие части)
    }

// Применение форматирования к коду подразделения
    codeInput.addEventListener('input', function() {
      let value = codeInput.value.replace(/\D/g, '');
      if (value.length > 3) {
        value = value.slice(0, 3) + '-' + value.slice(3, 6);
      }
      codeInput.value = value;
    });

// События обновления
    seriesInput.addEventListener('input', updateFullPassport);
    numberInput.addEventListener('input', updateFullPassport);
    fioInput.addEventListener('input', splitFIO);

// Инициализация при загрузке
    if (seriesInput.value.trim() === '' || seriesInput.value.trim().replace(/0/g, '') === '') {
    splitFullPassport();
      }
    splitFIO();
    
    if (passportFullInput.value.trim() !== '') {
    splitFullPassport();
      }

// Установка значения чекбокса в соответствии с полем CITIZENSHIP
    if (citizenshipInput.value === '1') {
      citizenshipCheckbox.checked = true;
    } else {
      citizenshipCheckbox.checked = false;
    }

// Событие изменения чекбокса
    citizenshipCheckbox.addEventListener('change', function() {
      if (citizenshipCheckbox.checked) {
        citizenshipInput.value = '1';
      } else {
        citizenshipInput.value = '0';
      }
    });

    isCompanyCheckbox.addEventListener('change', function() {
      const display = isCompanyCheckbox.checked ? '' : 'none';
      companyNameRow.style.display = display;
      companyDataRow.style.display = display;
    });

    jQuery('#show_fio').click(function() {
      jQuery('#simple_fio').addClass('d-none');
      jQuery('#full_fio').css('display', 'block');
    });

    jQuery('#hide_fio').click(function() {
      jQuery('#simple_fio').removeClass('d-none');
      jQuery('#full_fio').css('display', 'none');
    });
  });
</script>

  <script type='text/javascript'>
  document.addEventListener('DOMContentLoaded', function() {
    const seriesInput = document.getElementById('PASPORT_SERIES');
    const numberInput = document.getElementById('PASPORT_NUMBER');
    const citizenshipInput = document.getElementById('CITIZENSHIP');

// Установка значения по умолчанию для поля CITIZENSHIP
    if (citizenshipInput.value === '') {
      citizenshipInput.value = '1';
    }

// Событие изменения чекбокса
    document.getElementById('citizenship_checkbox').addEventListener('change', function() {
      if (this.checked) {
        citizenshipInput.value = '1';
        seriesInput.setAttribute('pattern', '\\d{4}');
        seriesInput.setAttribute('title', 'Введите серию в формате XXXX');
        numberInput.setAttribute('pattern', '\\d{6}');
        numberInput.setAttribute('title', 'Введите номер в формате XXXXXX');
      } else {
        citizenshipInput.value = '0';
        seriesInput.removeAttribute('pattern');
        seriesInput.removeAttribute('title');
        numberInput.removeAttribute('pattern');
        numberInput.removeAttribute('title');
      }
    });

// Инициализация при загрузке
    if (citizenshipInput.value === '1') {
      seriesInput.setAttribute('pattern', '\\d{4}');
      seriesInput.setAttribute('title', 'Введите серию в формате XXXX');
      numberInput.setAttribute('pattern', '\\d{6}');
      numberInput.setAttribute('title', 'Введите номер в формате XXXXXX');
    } else {
      seriesInput.removeAttribute('pattern');
      seriesInput.removeAttribute('title');
      numberInput.removeAttribute('pattern');
      numberInput.removeAttribute('title');
    }
  });
  </script>
