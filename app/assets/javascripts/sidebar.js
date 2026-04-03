document.addEventListener('DOMContentLoaded', function () {
  var trigger = document.querySelector('.open-sidebar');
  var sidebar = document.querySelector('.sidebar');
  var overlay = document.querySelector('.sidebar__overlay');

  if (!trigger || !sidebar) return;

  trigger.addEventListener('click', function (e) {
    e.stopPropagation();
    sidebar.classList.remove('translate-x-full');
    sidebar.classList.add('translate-x-0');
    if (overlay) overlay.classList.remove('hidden');
  });

  function closeSidebar() {
    sidebar.classList.add('translate-x-full');
    sidebar.classList.remove('translate-x-0');
    if (overlay) overlay.classList.add('hidden');
  }

  if (overlay) overlay.addEventListener('click', closeSidebar);

  document.addEventListener('click', function (e) {
    if (!sidebar.contains(e.target) && !trigger.contains(e.target)) {
      closeSidebar();
    }
  });
});
