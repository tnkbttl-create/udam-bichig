const assert=require('node:assert/strict');const C=require('./core.js');
const p=(id,givenName,parents=[],extra={})=>({id,givenName,clanName:'',parentIds:parents,children:[],partnerId:'',...extra});
let t=[p('g','Grandparent'),p('f','Father',['g']),p('m','Mother'),p('a','Child',['f','m']),p('b','Child',['f','m']),p('c','Grandchild',['b'])];
let m=C.merge(t,'a','b');assert.equal(m.length,5);assert.deepEqual(m.find(p=>p.id==='c').parentIds,['a']);assert.deepEqual(m.find(p=>p.id==='a').parentIds,['f','m']);assert.equal(m.find(p=>p.id==='f').partnerId,'');
assert.throws(()=>C.merge([p('a','Same',[],{birthYear:'1969'}),p('b','Same',[],{birthYear:'1980'})],'a','b'));
assert.throws(()=>C.merge([p('a','Same'),p('b','Same',['a'])],'a','b'));
const diamond=[p('g','G'),p('f','F',['g']),p('m','M',['g']),p('c','C',['f','m'])];assert.equal(C.layout(diamond).edges.length,4);assert.equal(C.layout(diamond).positions.size,4);assert.equal(C.layout(diamond,true).edges.length,4);
const cyc=[p('a','A',['b']),p('b','B',['a'])];assert(C.issues(cyc).some(x=>x.type==='cycle'));assert.equal(C.layout(cyc).positions.size,2);
assert(C.issues([p('a','Parent',[],{birthYear:'1990'}),p('b','Child',['a'],{birthYear:'1995'})]).some(x=>x.type==='age'));
assert(C.compatible(p('a','Туул',[],{birthYear:'1969'}),p('b','Туул')));assert(!C.compatible(p('a','Туул',[],{birthYear:'1969'}),p('b','Туул',[],{birthYear:'1970'})));
assert.deepEqual(C.normalize([p('a','A',['missing'])])[0].parentIds,[]);
const pairs=[p('a','A',[],{partnerId:'b'}),p('b','B',[],{partnerId:'a'})];assert.equal(C.layout(pairs).edges.length,1);
console.log('PASS: merge identity rewrites, co-parent privacy, conflicting years, cycle prevention, repeated ancestors, all edges, age checks, mutual partner edge');

assert.equal(C.dateError({birthYear:'2000',birthMonth:'2',birthDay:'29'}),'');
assert(C.dateError({birthYear:'2001',birthMonth:'2',birthDay:'29'}));
assert.equal(C.dateError({birthYear:'1995'}),'');
assert.equal(C.dateError({birthMonth:'2',birthDay:'29'}),'');
assert(!C.compatible({name:'Test',birthMonth:'1'},{name:'Test',birthMonth:'2'}));

const provenance=C.merge([p('r1','Same',[],{externalRefs:[{ownerId:'one',personId:'x'}]}),p('r2','Same',[],{externalRefs:[{ownerId:'two',personId:'y'}]})],'r1','r2');assert.equal(provenance[0].externalRefs.length,2);

const unit=[p('u1','Parent A',[],{partnerId:'u2'}),p('u2','Parent B',[],{partnerId:'u1'}),p('u3','Child 1',['u1','u2']),p('u4','Child 2',['u1','u2'])];
for(const horizontal of [false,true]){const layout=C.layout(unit,true);if(horizontal)for(const [id,pos]of layout.positions)layout.positions.set(id,{...pos,x:pos.y*1.7,y:pos.x});const links=C.connections(unit,layout,horizontal);assert.equal(links.filter(l=>l.type==='family').length,1);assert.equal(links.filter(l=>l.type==='partner').length,1);assert.equal(links.flatMap(l=>l.relations).filter(r=>r.type==='parent').length,4);assert.deepEqual(links.find(l=>l.type==='family').children,['u3','u4']);}
const single=unit.map(q=>q.id==='u3'||q.id==='u4'?{...q,parentIds:['u1']}:q);assert(!C.connections(single,C.layout(single,true)).flatMap(l=>l.relations).some(r=>r.type==='parent'&&r.from==='u2'));console.log('PASS v24: sibling family junctions, both orientations, no inferred co-parent');
