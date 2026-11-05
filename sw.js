/* Network-first application shell: always prefer newest deployed HTML. */
const CACHE = 'udam-bichig-shell-v23-1';
const SHELL = ['./', './index.html', './manifest.webmanifest', './icon-192.png', './icon-512.png', './offline.html', './core.js'];
self.addEventListener('install', event => { event.waitUntil((async()=>{
  const cache=await caches.open(CACHE);
  await Promise.allSettled(SHELL.map(async path=>{
    const response=await fetch(new Request(path,{cache:'reload'}));
    if(response.ok)await cache.put(path,response);
  }));
  await self.skipWaiting();
})()); });
self.addEventListener('activate', event => { event.waitUntil((async()=>{
  const keys=await caches.keys();
  await Promise.all(keys.filter(k=>k.startsWith('udam-bichig-')&&k!==CACHE).map(k=>caches.delete(k)));
  await self.clients.claim();
})()); });
self.addEventListener('fetch',event=>{
  const req=event.request;
  if(req.method!=='GET')return;
  const url=new URL(req.url);
  if(url.origin!==self.location.origin)return; // Never cache Supabase credentials/data or external CDN.
  if(req.mode==='navigate'){
    event.respondWith((async()=>{
      try{const res=await fetch(new Request(req,{cache:'no-store'}));
        if(res.ok){const cache=await caches.open(CACHE);cache.put('./index.html',res.clone()).catch(()=>{});}
        return res;
      }catch(e){const cache=await caches.open(CACHE);return await cache.match('./index.html')||await cache.match('./offline.html')||Response.error()}
    })());return;
  }
  event.respondWith((async()=>{
    try{const res=await fetch(req);
      if(res.ok && ['.js','.css','.png','.webmanifest','.json'].some(x=>url.pathname.endsWith(x))){
        const cache=await caches.open(CACHE);cache.put(req,res.clone()).catch(()=>{});
      }
      return res;
    }catch(e){return await caches.match(req)||Response.error()}
  })());
});
