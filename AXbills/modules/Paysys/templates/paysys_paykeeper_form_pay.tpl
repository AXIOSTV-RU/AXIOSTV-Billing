<div class='card card-primary card-outline form-horizontal'>
  <div class='card-header with-border text-center pb-0'>
    <h4>_{BALANCE_RECHARCHE}_ %LOGIN%</h4>
  </div>
  <div class='card-body'>
      <div>
       <div class='alert alert-info' role='alert'>
        <h3 class='alert alert-info text-center'>Оплата картой. <span class='colortext'>Комиссия 0% (платеж через банковскую карту любого банка)</span></h3>
        <h6>
          Оплата заказа банковской картой. Оплата происходит через сервис Paykeeper с использованием банковских карт следующих платёжных систем:
        </h6>
        <div>
          Для оплаты (ввода реквизитов Вашей карты) Вы будете перенаправлены на платёжный шлюз Paykeeper. Соединение с платёжным шлюзом и передача информации осуществляется в защищённом режиме с использованием протокола шифрования SSL. В случае если Ваш банк поддерживает технологию безопасного проведения интернет-платежей Verified By Visa, MasterCard SecureCode, MIR Accept, J-Secure, для проведения платежа также может потребоваться ввод специального пароля.<BR>
          Настоящий сайт поддерживает 256-битное шифрование. Конфиденциальность сообщаемой персональной информации обеспечивается Paykeeper. Введённая информация не будет предоставлена третьим лицам за исключением случаев, предусмотренных законодательством РФ. Проведение платежей по банковским картам осуществляется в строгом соответствии с требованиями платёжных систем МИР, Visa Int., MasterCard Europe Sprl
        </div>
        <div>
          <h6>Возврат денежных средств.</h6>
          При отказе клиента от оплаченного заказа, возврат переведенных средств, производится на Ваш банковский счет в течение 5—30 рабочих дней (срок зависит от Банка, который выдал Вашу банковскую карту), за вычетом документально подтвержденных расходов.
        </div>
      </div>

    </div>
    <form method='POST' action='%URL%' accept-charset='utf-8'>
      <div class='form-group row'>
        <label for='orderid' class='col-sm-2 col-md-2 col-form-label'>_{TRANSACTION}_ #:</label>
        <div class='col-sm-10 col-md-10'>
          <input type='text' class='form-control' id='orderid'  name='orderid' value='%OPERATION_ID%' readonly>
        </div>
      </div>

      <div class='form-group row'>
        <label for='clientid' class='col-sm-2 col-md-2 col-form-label'>_{LOGIN}_:</label>
        <div class='col-sm-10 col-md-10'>
          <input class='form-control' type='text' id='clientid' name='clientid' value='%LOGIN%' readonly>
        </div>
      </div>

      <div class='form-group row'>
        <label for='payment_amount' class='col-sm-2 col-md-2 col-form-label'>_{SUM}_:</label>
        <div class='col-sm-10 col-md-10'>
          <input class='form-control' type='text' id='sum' name='sum'
            value='%PAYMENT_AMOUNT%' readonly>
        </div>
      </div>

      <div class='form-group row'>
        <label for='payment_amount' class='col-sm-2 col-md-2 col-form-label'>_{CELL_PHONE}_:</label>
        <div class='col-sm-10 col-md-10'>
          <input class='form-control' type='text' id='client_phone' name='client_phone'
            value='%CELL_PHONE%'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='payment_amount' class='col-sm-2 col-md-2 col-form-label'>E-Mail:</label>
        <div class='col-sm-10 col-md-10'>
          <input class='form-control' type='text' id='client_email' name='client_email'
            value='%EMAIL%'>
        </div>
      </div>

      <input class="btn btn-primary float-right" type='submit' value='Перейти к оплате' />
    </form>
  </div>
</div>
