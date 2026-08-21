document.addEventListener('open-tree-toggle', function(event) {
  let item = event.detail.parent.parent();
  let id = item.data('id');
  let type = item.data('type');
  if (item.find('ul.ul-list').length > 0) return;

  if (!id || !type) return;

  item.append(`<ul class='ul-spinner'><span class='fa fa-spin fa-spinner' style='padding: 0 1.8em;'></span></ul>`);
  let params = {
    skip_input: item.find('input.tree_box').length <= 0,
    skip_url: item.find('a.text-info').length <= 0,
    parent_checked: item.find('input.tree_box').first().prop("checked"),
  }

  if (type === 'district') {
    fetch(`/api.cgi/districts?PARENT_ID=${id}&PARENT_NAME=_SHOW&PAGE_ROWS=1000000&SORT=name`)
      .then(response => {
        if (!response.ok) throw response;
        return response;
      })
      .then(response => response.json())
      .then(data => {
        item.find('ul.ul-spinner').remove();
        params.url = '?get_index=form_districts&full=1&chg=';
        params.key = 'name';
        createNodes(data, 'district', item, params);

        if (event.detail.parent.data('open-parent')) openParentItems();
        event.detail.parent.removeAttr('data-open-parent')
      })
      .catch(e => {
        item.find('ul.ul-spinner').remove();
        console.log(e);
      });

    fetch(`/api.cgi/streets?DISTRICT_ID=${id}&PAGE_ROWS=1000000&SORT=street_name`)
      .then(response => {
        if (!response.ok) throw response;
        return response;
      })
      .then(response => response.json())
      .then(data => {
        item.find('ul.ul-spinner').remove();
        params.url = '?get_index=form_streets&full=1&chg=';
        params.key = 'streetName';
        createNodes(data, 'street', item, params);

        if (event.detail.parent.data('open-parent')) openParentItems();
        event.detail.parent.removeAttr('data-open-parent')
      })
      .catch(e => {
        item.find('ul.ul-spinner').remove();
        console.log(e);
      });
  }

  if (type === 'street') {
    fetch(`/api.cgi/builds?STREET_ID=${id}&PAGE_ROWS=1000000`)
      .then(response => {
        if (!response.ok) throw response;
        return response;
      })
      .then(response => response.json())
      .then(data => {
        item.find('ul.ul-spinner').remove();
        params.url = `?get_index=form_streets&full=1&BUILDS=${id}&chg=`;
        params.key = 'number';
        params.skip_collapse = true;
        createNodes(data, 'build', item, params);
      })
      .catch(e => {
        item.find('ul.ul-spinner').remove();
        console.log(e);
      });
  }
});

jQuery(document).ready(function () {
  openParentItems();
});

function openParentItems () {
  jQuery('.ul-item > span.parent > span.text-info').each(function() {
    let openBtn = jQuery(this).parent().parent().find('.children-toggle').first();
    if (openBtn.length < 1) return;

    if (openBtn.children('i.fa-plus-circle').length < 1) return;

    openBtn.attr('data-open-parent', 1);
    openBtn.click();
  });
}

function checkNodes() {
  var a = jQuery(this).prop('checked');
  if (a) {
    jQuery(this).parent().addClass('text-success');
  } else {
    jQuery(this).parent().removeClass('text-success');
  }
  jQuery(this).closest('li').find('ul').find('input').each(function () {
    if (a) {
      jQuery(this).prop('checked', true);
      jQuery(this).prop('disabled', true);
      jQuery(this).parent().addClass('text-success');
    } else {
      jQuery(this).prop('checked', false);
      jQuery(this).prop('disabled', false);
      jQuery(this).parent().removeClass('text-success');
    }
  });
}

function createNodes(items, type, parent, attr) {
  let node = drawTree(items, type, attr);
  parent.append(node)
}