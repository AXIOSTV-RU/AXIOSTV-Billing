<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/leaflet.css" />
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/leaflet.js"></script>

<div id="search_geo" class="card card-primary card-outline">
  <div class="card-header d-flex flex-nowrap justify-content-between">
    <div class="card-title">
      <h4 class="card-title table-caption">Добавление привязки устройств к карте</h4>
    </div>    
  </div>
  <div class="card-body">
    <div class="row">
      <div class="col-4">
        <input type="text" id="address-input" value="г. Липецк, ул. Терешковой, д. 22" placeholder="Введите адрес..." class="form-control">               
        <a href="#" class="btn btn-primary" id="save_latlng" style="display:none">Сохранить</a>
        <div class="alert alert-primary" role="alert" id="alert" style="margin-top:10px;display:none">
          Сохранено! Обновляем данные...
        </div>
        <div id="sidebar"></div>
      </div>
      <div class="col-8">
        <div id="map"></div>
      </div>
    </div>
    
  </div>
</div>



<style>
#map {
  min-height:700px;
}
#sidebar {
  margin-top:10px;
  height: 610px;
  overflow-y:scroll;
}
#sidebar .line {
  margin-bottom: 20px;
  border: 1px solid #e8e8e8;
  border-radius: 10px;
  padding: 10px;
}
#sidebar .line.active {
  border-color: #3c8dbc;
}
#save_latlng {
  margin-top: 10px;
}
.leaflet-tooltip {
  border-radius: 50%;
  height: 20px;
  width: 20px;
  padding: 0;
  text-align:center;
  color: red;
  /*margin-left:-15px;*/
}
</style>
<script>

var new_marker_id = 0
jQuery(function(){

  jQuery('#save_latlng').click(function(e){
    e.preventDefault()

    var arr = ""
    var i = 0
    jQuery('.line').each(function(index,item){
      //if (i<2) {
        var 
          item = jQuery(item),
          id = item.data('id'), 
          title = item.find('.title').text(),
          lat = item.find('.lat').text(),
          lng = item.find('.lng').text()
         
          i++

          arr += '\{"device_id":'+id+',"title":"'+title+'","latitude":'+lat+',"longitude":'+lng+'\},'
      //}
    })
    arr = arr.substring(0, arr.length - 1);
    
    console.log(arr)
    var index_page = "%INDEX_PAGE%";
    jQuery.ajax({
     // url: '/admin/index.cgi?qindex=439&api_js=1&address_devices_update=1&arr='+arr+'&address='+jQuery('#address-input').val(),
      url: '/admin/index.cgi?qindex='+index_page+'&api_js=1&address_devices_update=1&arr='+arr+'&address='+jQuery('#address-input').val(),
      type: 'GET',
      //data: {arr: arr},
      contentType: false,
      cache: false,
      processData: false,
      //dataType: 'json',
      success: function (result) {
        
        jQuery('#sidebar').html('')
        jQuery('#save_latlng').hide()
        jQuery('#alert').show()
        setTimeout(function(){
          jQuery('#alert').hide()
          searchAddress(jQuery('#address-input').val())
        },3000)

        markers.forEach(function(marker) {
          marker.remove()
        })
        
      },
      fail: function (error) {
        
      },
      done: function(result) {
        
      }, 
      always: function(result) {
        
      }
    });
  })

  
  jQuery(document).on('click','#sidebar .line',function(e){
    e.preventDefault()
    jQuery('#sidebar .line').removeClass('active')
    jQuery(this).addClass('active')

    var lat = jQuery(this).find('.lat').text()
    var lng = jQuery(this).find('.lng').text()

    if (lat == '0' && lng == '0') {
      new_marker_id = jQuery(this).data('id')
      return
    }

    new_marker_id = 0

    markers.forEach(function(marker) {
      var latlng = marker.getLatLng();
      if (latlng.lat == lat && latlng.lng == lng) {
        //console.log(marker)
        marker.openPopup()
      }
    })
  })

  jQuery(document).on('click','.line .lat',function(){
    var elem = jQuery(this)
    elem.parent().find('.lng').show()
    elem.hide()
    elem.parent().find('input').remove()
    elem.after('<input class="lat_input" />')
    elem.parent().find('input').val(elem.text())
    console.log(elem.find('input'))
  })

  jQuery(document).on('click','.line .lng',function(){
    var elem = jQuery(this)
    elem.parent().find('.lat').show()
    elem.hide()
    elem.parent().find('input').remove()
    elem.after('<input class="lng_input" />')
    elem.parent().find('input').val(elem.text())
    console.log(elem.find('input'))
  })

  jQuery(document).on('keyup','.line .lng_input',function(e){
    var elem = jQuery(this)
    var id = elem.parent().data('id')
    var lng = elem.parent().find('.lng').text()
    var lat = elem.parent().find('.lat').text()

    

    if (e.keyCode === 13) {

      markers.forEach(function(marker) {
        var latlng = marker.getLatLng();
        if (latlng.lat == lat && latlng.lng == lng) {
          console.log(marker)
          //marker.openPopup()

          marker.setLatLng({lng: elem.val(), lat: lat})
        }
      })

      elem.prev().text(elem.val()).show()
      elem.hide()
    }
  })

  jQuery(document).on('keyup','.line .lat_input',function(e){
    var elem = jQuery(this)
     var id = elem.parent().data('id')
     var lng = elem.parent().find('.lng').text()
     var lat = elem.parent().find('.lat').text()

    if (e.keyCode === 13) {

      markers.forEach(function(marker) {
        var latlng = marker.getLatLng();
        if (latlng.lat == lat && latlng.lng == lng) { 
          console.log(marker)
          
          marker.setLatLng({lat: elem.val(), lng: lng})
        }
      })

      elem.prev().text(elem.val()).show()
      elem.hide()
    }
  })

})


var map = L.map('map').setView([0, 0], 2);

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '© OpenStreetMap contributors'
}).addTo(map);

var markers = [];
var idCounter = 1;
var activeMarker = null;

function addMarker(latlng,id,title) {
  //console.log(latlng)
  var marker = L.marker(latlng, {
    clickable: false,
    draggable: true,
    icon: L.icon({
      iconUrl: 'icon.png',
      iconSize: [20, 20],
      iconAnchor: [10, 10],
    })
  });
  marker.bindTooltip(String(id), {
    permanent: true,
    direction: 'center'});
  marker.addTo(map);

  //marker.bindPopup(String(title)).openPopup();
  marker.bindPopup(String(title));
  markers.push(marker);
  updateSidebar();
  //idCounter++;

  marker.on('dragstart', function(e) {
    activeMarker = marker;
  });

  marker.on('dragend', function(e) {
    console.log(activeMarker)
    console.log(activeMarker._tooltip._content)
    jQuery('#sidebar .line').removeClass('active')
    jQuery('#sidebar .line[data-id='+activeMarker._tooltip._content+']').addClass('active')
    
    jQuery('#sidebar').scrollTop(jQuery('#sidebar').scrollTop() + jQuery('#sidebar .line[data-id='+activeMarker._tooltip._content+']').position().top - 100);

    activeMarker = null;
    updateSidebar();
  });
}

function updateSidebar() {
  var sidebar = document.getElementById('sidebar');
  //sidebar.innerHTML = '';
  markers.forEach(function(marker) {
    var latlng = marker.getLatLng();
    console.log(latlng)
    jQuery('#sidebar .line[data-id='+marker._tooltip._content+'] .lat').text(latlng.lat)
    jQuery('#sidebar .line[data-id='+marker._tooltip._content+'] .lng').text(latlng.lng)
    //var p = document.createElement('p');
    //p.textContent = marker._popup._content + ': ' + latlng.lat + ', ' + latlng.lng;
    //sidebar.appendChild(p);
  });
}

map.on('click', function(e) {
  if (activeMarker) {
    //activeMarker.setLatLng(e.latlng);
  } else {
    //addMarker(e.latlng);
    //alert(e.latlng)
  }

  if (new_marker_id != 0) {
    var id = jQuery('.line.active').data('id')
    var title = jQuery('.line.active .title').text()
    jQuery('.line.active .lat').text(e.latlng.lat)
    jQuery('.line.active .lng').text(e.latlng.lng)
    addMarker(e.latlng,id,title)
  }
});

var addressInput = document.getElementById('address-input');
addressInput.addEventListener('keydown', function(event) {
  if (event.keyCode === 13) {
    event.preventDefault();
    var address = addressInput.value;
    if (address) {
      searchAddress(address);
    }
  }
});

function searchAddress(address) {
  address = address.replace('г. ', '',address)
  address = address.replace('д. ', '',address)
  
  fetch('https://nominatim.openstreetmap.org/search?format=json&q=' + encodeURIComponent(address))
    .then(function(response) {
      return response.json();
    })
    .then(function(data) {
      if (data.length > 0) {
        var { lat, lon } = data[0];
        var latlng = L.latLng(lat, lon);
        map.setView(latlng, 19);
      }
    })
    .catch(function(error) {
      console.error('Error:', error);
    });

  get_cameras()
  jQuery('#save_latlng').show()
}


function get_cameras() {
  var index_page = "%INDEX_PAGE%";
  jQuery.ajax({
    url: '/admin/index.cgi?qindex='+index_page+'&api_js=1&get_address_devices_list='+jQuery('#address-input').val(),
      // url: '/admin/index.cgi?qindex=439&api_js=1&get_address_devices_list='+jQuery('#address-input').val(),
      type: 'GET',
      contentType: false,
      cache: false,
      processData: false,
      dataType: 'json',
      success: function (result) {
        console.log(result.devices)
        jQuery('#sidebar').html('')
        for (var i = result.devices.length - 1; i >= 0; i--) {
          var html = '<div class="line" data-id="'+result.devices[i].device_id+'">'
          html += 'id: ' + result.devices[i].device_id + '<br>'
          html += 'latitude: <span class="lat">' + result.devices[i].latitude + '</span><br>'
          html += 'longitude: <span class="lng">' + result.devices[i].longitude + '</span><br>'
          html += 'title: <span class="title">' + result.devices[i].title + '</span><br>'
          html += '</div>'
          jQuery('#sidebar').append(html)   
          
          var latlng = {lat: result.devices[i].latitude, lng: result.devices[i].longitude}          
          addMarker(latlng,result.devices[i].device_id,result.devices[i].title)
        }
      },
      fail: function (error) {
        
      },
    });
}
</script>