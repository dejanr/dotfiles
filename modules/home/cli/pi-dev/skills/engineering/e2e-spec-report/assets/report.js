const cases = [...document.querySelectorAll('.case')];
const search = document.querySelector('#search');
search?.addEventListener('input', () => {
  const query = search.value.toLocaleLowerCase();
  for (const item of cases) item.hidden = !item.textContent.toLocaleLowerCase().includes(query);
  document.querySelector('#visible-count').textContent = cases.filter(item => !item.hidden).length;
});
for (const button of document.querySelectorAll('button[data-view]')) {
  button.addEventListener('click', () => {
    document.body.dataset.view = button.dataset.view;
    for (const other of document.querySelectorAll('button[data-view]')) other.setAttribute('aria-pressed', String(other === button));
  });
}
