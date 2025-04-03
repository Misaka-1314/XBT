export function debounce(func, duration) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(function(){
      func.call(this, ...args);
    }, duration);
  }
}