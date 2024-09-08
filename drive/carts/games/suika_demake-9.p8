pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--watermelon game for pico8
--@spoike


--[[
ROOT2     = 0x1.6109 --1.41421356237
PI        = 0x3.243f --3.14159265359
TWOPI     = 0x6.487e --6.28318530718
INV_TWOPI = 0x0.28be --0.159154943091
]]

-- zero small absolute values
function zero(x) return x<0x0.002 and x>0xffff.ffe0 and 0 or x end

-- returns min and max of x, y
function minmax(x, y) return min(x, y), max(x, y) end

-- trig function takes angle in radians
function cos_sin(a) a*=0x0.28be return cos(a), sin(-a) end

-- 2d transform
function transform(x, y, tx, ty, ta)
  local ca, sa = cos_sin(ta)
  return x*ca-y*sa+tx, x*sa+y*ca+ty
end
-- core physics
--[[
core physics code
]]
-- aabb

function aabb(x1, y1, x2, y2)
  local self
  self = {
    x1=x1 or 0x7fff, y1=y1 or 0x7fff,
    x2=x2 or 0x8000, y2=y2 or 0x8000,
    set=function(x1, y1, x2, y2)
      self.x1, self.y1, self.x2, self.y2 =
        x1 or 0x7fff, y1 or 0x7fff, x2 or 0x8000, y2 or 0x8000
    end,
    overlaps=function(b)
      return self.x2>=b.x1 and self.x1<=b.x2 and
             self.y2>=b.y1 and self.y1<=b.y2
    end,
    contains=function(b)
      return b.x1>=self.x1 and b.y1>=self.y1 and
             b.x2<=self.x2 and b.y2<=self.y2
    end
  }
  return self
end
-- viewport
--[[
viewport allows transformations between world space (metres), and screen space (pixels)
params:
args - table of optional parameters
ox, oy - origin in screen space
scale - pixels per metre
]]

function viewport(args)
  args = args or {}

  local scale = args.scale or 16
  local m11, m12, m13, m21, m22, m23 =
    scale, 0, args.ox or 64,
    0, -scale, args.ox or 64

  return {
    translate=function(tx, ty)
      --tx/=scale ty/=scale
      m13, m23 = m11*tx+m12*ty+m13, m21*tx+m22*ty+m23
    end,
    scale=function(s) scale*=s m11*=s m12*=s m21*=s m22*=s end,
    to_screen=function(x, y) -- converts metres to pixels
      return m11*x+m12*y+m13, m21*x+m22*y+m23
    end
  }
end
-- scene
--[[
scene stores all information/functionality for a physics scene.
measurements in a scene are in SI units, metres/kg
params:
args - table of optional parameters
g - gravity
slop - allowed overlap before collision response
damp - damping
isteps - solver steps
sframes - frames before bodies are put to sleep
beta - for baumgarte stabilisation, proportion of positional correction
size - the size of the simulation area, bodies outside this region are killed
]]

--[[
-- ids for events
ON_COLLISION_ENTER  = 0x01
ON_COLLISION_EXIT   = 0x02
ON_BODY_SLEEP       = 0x03
ON_BODY_WAKE        = 0x04
ON_BODY_DEAD        = 0x05
]]--

function scene(args)
  args = args or {}

  local size = args.size or 10
  local g, slop, damp, isteps, sframes, svelocity, beta, cmanager, box, constraints, forces =
    args.g or -9.8, args.slop or 0x0.08, args.damp or 1, args.isteps or 4, args.sframes or 100, args.svelocity or 0x0.4, args.beta or 0.2,
    sweep_and_prune(), aabb(-size, -size, size, size), {}, {}
  local nextid, alive, dead, awake, dynamic, x, y, a, vx, vy, va, mass, imass, imoi,
    geom, layer, rest, frict, contact_ids, listeners,
    island, island_vx, island_vy, island_va, island_count, island_sframes =
    1, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}

  local function send_messages(args)
    foreach(args, function(evt)
      if (listeners[evt.id]) listeners[evt.id].on_event(evt)
    end)
  end
  local function find(id) return id==island[id] and id or find(island[id]) end
  local function union(id1, id2) id2, id1 = minmax(find(id1), find(id2)) island[id1] = id2 end

  --[[
  removes a body from the system
  params:
  id - id of the body
  ]]
  local function remove_body(id)
    send_messages{ { id=id, event=0x05 } }
    dead[id], alive[id], geom[id], listeners[id] = true
    for cid in pairs(contact_ids) do -- remove contact ids
      if (id==shr(band(cid, 0xff00), 8) or id==band(cid, 0xff)) contact_ids[cid] = nil
    end
    cmanager.remove_body(id)
  end

  --[[
  identifies if a body is awake
  params:
  id - id of the body
  ]]
  local function is_awake(id) return dynamic[id] and awake[find(id)] end

  local function sleep(id)
    local isle = island[id]
    if awake[isle] then
      island_sframes[isle], awake[isle] = 0
      for id in pairs(alive) do if (island[id]==isle) send_messages{ { id=id, event=0x03 } } end
    end
  end

  local function wake(id)
    local isle = island[id]
    if not awake[isle] and dynamic[isle] then
      awake[isle] = true
      for id in pairs(alive) do if (island[id]==isle) send_messages{ { id=id, event=0x04 } } end
    end
  end

  --[[
  apply a force to a body
  params:
  id - id of the body
  dt - time step
  fx, fy - force in x, y direction
  px, py - point at which force is applied
  ]]
  local function apply_force(id, dt, fx, fy, px, py)
    wake(id)
    px, py = px and px-x[id] or 0, py and py-y[id] or 0
    vx[id] += fx*imass[id]*dt
    vy[id] += fy*imass[id]*dt
    va[id] -= (fx*py-fy*px)*imoi[id]*dt
    return vx[id], vy[id], va[id]
  end

  --[[
  apply an impulse to a body
  params:
  id - id of the body
  px, py, pa - x, y, angular components of the impulse
  ]]
  local function apply_impulse(id, px, py, pa)
    wake(id)
    vx[id] += px*imass[id]
    vy[id] += py*imass[id]
    va[id] += pa*imoi[id]
    return vx[id], vy[id], va[id]
  end

  -- contact solver
  local function contact(id1, id2, nx, ny)
    local lambdan, lambdat, r, f, jn3, jn6, jmn, b, jt3, jt6, jmt =
      0, 0, 0.5*(rest[id1]+rest[id2]), sqrt(frict[id1]*frict[id2])

    return {
      nx=nx,ny=ny,
      eval=function(dt, dist, px1, py1, px2, py2)
        local rx1, ry1, rx2, ry2, vx1, vy1, va1, vx2, vy2, va2, imass1, imoi1, imass2, imoi2 =
          zero(px1-x[id1]), zero(py1-y[id1]), zero(px2-x[id2]), zero(py2-y[id2]),
          vx[id1], vy[id1], va[id1], vx[id2], vy[id2], va[id2],
          imass[id1], imoi[id1], imass[id2], imoi[id2]

        jn3, jn6 = rx1*ny-ry1*nx, ry2*nx-rx2*ny

        if (nx*vx1+ny*vy1+jn3*va1-nx*vx2-ny*vy2+jn6*va2>=0) return false

        -- warmstart
        if abs(lambdan)+abs(lambdat)>0 then
          local px, py = nx*lambdan-ny*lambdat, ny*lambdan+nx*lambdat
          vx1, vy1, va1 = apply_impulse(id1, px, py, rx1*py-ry1*px)
          vx2, vy2, va2 = apply_impulse(id2, -px, -py, ry2*px-rx2*py)
        end

        local nx2, ny2 = nx^2, ny^2
        jmn, b = nx2*imass1+ny2*imass1+jn3*imoi1*jn3+nx2*imass2+ny2*imass2+jn6*imoi2*jn6,
                 -(beta/dt)*dist+r*min(0, ((vx1-py1*va1)-(vx2-py2*va2))*nx+
                                          ((vy1+px1*va1)-(vy2-px2*va2))*ny)

        jt3, jt6 = rx1*nx+ry1*ny, -(rx2*nx+ry2*ny)
        jmt = ny2*imass1+nx2*imass1+jt3*imoi1*jt3+ny2*imass2+nx2*imass2+jt6*imoi2*jt6

        return true
      end,
      solve=function()
        local vx1, vy1, va1, vx2, vy2, va2, deln, delt =
          vx[id1], vy[id1], va[id1], vx[id2], vy[id2], va[id2]

        deln = max(lambdan-(nx*vx1+ny*vy1+jn3*va1-nx*vx2-ny*vy2+jn6*va2+b)/jmn, 0)-lambdan
        lambdan += deln

        delt = mid(-f*lambdan, lambdat-(-ny*vx1+nx*vy1+jt3*va1+ny*vx2-nx*vy2+jt6*va2)/jmt, f*lambdan)-lambdat
        lambdat += delt

        apply_impulse(id1, deln*nx-delt*ny, deln*ny+delt*nx, deln*jn3+delt*jt3)
        apply_impulse(id2, delt*ny-deln*nx, -deln*ny-delt*nx, deln*jn6+delt*jt6)

        return deln^2+delt^2<0x0.001
      end
    }
  end

  local contacts, prev_contacts = {}, {}

  return {
    --[[
    adds a body to the system
    params:
    args - table of optional parameters
    x, y, a - position and rotation of the body
    mass - mass of the body, 0 indicates infinite mass
    moi - inertia of the body, 0 indicates infinite inertia
    rest - restitution
    frict - friction
    layer - which layer/layers the object is present in
    verts - table containing geometry
    listener - table containing an on_event(args) method for events
    ]]
    add_body=function(args)
      args = args or {}

      local id = next(dead)
      if (id) dead[id] = nil else id = nextid nextid += 1

      local verts = args.verts and args.verts or rectangle(1, 1)
      mass[id], geom[id] = args.mass or 1, geometry(verts.numv, verts.x, verts.y, verts.r)
      local moi = args.moi

      if not moi then
        moi = 0
        if mass[id]>0 then
          local nv, vx, vy = geom[id].numv
          for i=1,nv do
            vx, vy = geom[id].x[i], geom[id].y[i]
            moi += vx^2+vy^2
          end
          moi *= mass[id]/nv
        end
      end

      dynamic[id] = mass[id]>0 or moi>0

      alive[id], awake[id], island[id], island_sframes[id],
        x[id], y[id], a[id], vx[id], vy[id], va[id],
        imass[id], imoi[id], layer[id], rest[id], frict[id], listeners[id] =
        true, dynamic[id] or nil, id, 0,
        args.x or 0, args.y or 0, args.a or 0, 0, 0, 0,
        mass[id]>0 and 1/mass[id] or 0, moi>0 and 1/moi or 0,
        args.layer or 255, args.rest or 0.1, args.frict or 1,
        args.listener or nil

      geom[id].transform(x[id], y[id], a[id])
      cmanager.add_body(id, geom[id].aabb)

      return id
    end,
    remove_body=remove_body,
    position=function(id) return x[id], y[id], a[id] end, -- returns position/angle of a body
    velocity=function(id) return vx[id], vy[id], va[id] end, -- returns velocity of a body
    mass=function(id) return mass[id] end,
    inv_mass=function(id) return imass[id], imoi[id] end, -- returns inverse mass/inertia of a body
    is_dynamic=function(id) return dynamic[id] end, -- returns true if the body reacts to forces
    add_constraint=function(c) constraints[#constraints+1] = c end,
    add_force=function(f) forces[#forces+1] = f end,
    apply_force=apply_force,
    apply_impulse=apply_impulse,
    update=function(dt) -- update function called once per frame
      dt = dt or 1/stat(7)
      local solvers, id1, id2, cid, rid, dist, nx, ny, x1, y1, x2, y2 = {}

      -- apply gravity and initialise islands
      for id in pairs(alive) do
        if is_awake(id) then
          awake[id], island[id], island_vx[id], island_vy[id], island_va[id], island_count[id] =
            true, id, 0, 0, 0, 0
          apply_force(id, dt, 0, g*mass[id])
        end
      end

      -- apply forces
      foreach(forces, function(f) f.apply(dt) end)

      -- initialise constraints
      foreach(constraints, function(c)
        if(c.eval(dt)) solvers[#solvers+1] = c
      end)

      -- compute contacts, create solvers (including warmstarting)
      contacts, prev_contacts = prev_contacts, contacts
      while cmanager.has_more() do
        id1, id2 = cmanager.next()
        if band(layer[id1], layer[id2])>0 and (is_awake(id1) or is_awake(id2)) then
          local g1,g2=geom[id1],geom[id2]
          if g1.numv > 4 and g2.numv > 4 then
           -- simpler circle to circle collision
           rid, dist, nx, ny, x1, y1, x2, y2 = circles_collide(x[id1], y[id1], g1.r, x[id2], y[id2], g2.r)
          else
           rid, dist, nx, ny, x1, y1, x2, y2 = g1.collides(g2)
          end 
          if rid then
            wake(id1) wake(id2)
            if (dynamic[id1] and dynamic[id2]) union(id1, id2)
            cid = shl(id1, 8)+id2+shr(rid, 16)
            contacts[cid], prev_contacts[cid] = prev_contacts[cid]
            if dist>slop then
              if not contacts[cid] then
                contacts[cid] = contact(id1, id2, nx, ny)
                if not contact_ids[cid] then
                  contact_ids[cid] = true
                  send_messages{ { id=id1, event=0x01, cid=cid, body=id2, x=x1, y=y1, nx=nx, ny=ny, dist=dist },
                                 { id=id2, event=0x01, cid=cid, body=id1, x=x2, y=y2, nx=-nx, ny=-ny, dist=dist } }
                end
              end
              if (contacts[cid].eval(dt, dist-slop, x1, y1, x2, y2)) solvers[#solvers+1] = contacts[cid]
            end
          end
        end
      end

      -- free all old contacts
      for cid,c in pairs(prev_contacts) do
        id1, id2 = shr(band(cid, 0xff00), 8), band(cid, 0xff)
        if is_awake(id1) or is_awake(id2) then
          contact_ids[cid] = nil
          send_messages{ { id=id1, cid=cid, event=0x02, body=id2 },
                         { id=id2, cid=cid, event=0x02, body=id1 } }
        end
        prev_contacts[cid] = nil
      end

      -- solve all constraints
      for i=1,isteps do
        for j,s in pairs(solvers) do if (s.solve()) solvers[j] = nil end
        if (#solvers==0) break -- if no constraints remain end early
      end

      -- integrate velocities, transform bodies, compute island information
      -- remove bodies outside of simulation area
      for id in pairs(alive) do
        if is_awake(id) then
          local isle = find(id)
          awake[id], island[id] = id==isle and true or nil, isle
          x[id] += vx[id]*dt
          y[id] += vy[id]*dt
          a[id] += va[id]*dt
          island_vx[isle] += vx[id]^2
          island_vy[isle] += vy[id]^2
          island_va[isle] += va[id]^2
          island_count[isle] += 1
          vx[id] *= damp
          vy[id] *= damp
          va[id] *= damp
          geom[id].transform(x[id], y[id], a[id])

          if (box.overlaps(geom[id].aabb)) cmanager.update_body(id, geom[id].aabb) else remove_body(id)
        end
      end

      -- sleep islands with low movement
      for id in pairs(awake) do
        local count = island_count[id]
        local ivx, ivy, iva = island_vx[id]/count, island_vy[id]/count, island_va[id]/count
        island_sframes[id] = ivx+ivy+iva<svelocity and island_sframes[id]+1 or 0
        if (island_sframes[id]>sframes) sleep(id)
      end
    end,
    draw=function(vp)
      for id in pairs(alive) do
        color(island[id]%7+8)
        local cx, cy = vp.to_screen(x[id], y[id])
        geom[id].draw(vp)
        if not is_awake(id) then
          print('⧗', cx-3, cy-2)
        else
          local upy, upx = cos_sin(a[id])
          upx *= 2 upy *= 2
          line(cx-upx, cy-upy, cx+upx, cy+upy)
          line(cx-upy, cy+upx, cx+upy, cy-upx)
        end
      end
    end
  }
end
-- shape functions

--[[
creates an ngon
params:
r - radius
nv - num vertices
sx, sy - scale in x/y directions
ox, oy - offset
]]
function ngon(r, nv, sx, sy, ox, oy)
  sx, sy, ox, oy = r*(sx or 1), r*(sy or 1), ox or 0, oy or 0
  local x, y, angle, da = {}, {}, (nv==4) and 0x0.c90c or 0, -0x6.487e/nv
  for i=1,nv do
    x[i], y[i] = transform(1, 0, ox, oy, angle)
    x[i] *= sx y[i] *= sy
    angle += da
  end
  return { numv=nv, x=x, y=y, r=r }
end

function triangle(w, h, ox, oy) return ngon(0x1.6109, 3, w/2, h/2, ox, oy) end
function rectangle(w, h, ox, oy) return ngon(0x1.6109, 4, w/2, h/2, ox, oy) end

function capsule(w, h, nv, ox, oy)
  nv += nv%2

  local sphere = ngon(w/2, nv, 1, 1, ox, oy)
  local numv, sx, sy, x, y = sphere.numv, sphere.x, sphere.y, {}, {}

  for i=1,nv/2+1 do x[#x+1], y[#y+1] = sx[i], sy[i]-h/2 end
  x[#x+1], y[#y+1] =  sx[nv/2+1], sy[nv/2+1]+h/2
  for i=nv/2+2,nv do x[#x+1], y[#y+1] = sx[i], sy[i]+h/2 end
  x[#x+1], y[#y+1] =  sx[1], sy[1]+h/2

  return { numv=nv+2, x=x, y=y }
end
-- broadphase collision detection
--[[
broadphase collision detection using sweep and prune with axis aligned bounding boxes
]]
-- sweep and prune

function sweep_and_prune()
  local nump, x_id, y_id, x_val, y_val, x_minmax, y_minmax, x_spans, y_spans, count, cand, iter =
    2, { -1, -1 }, { -1, -1 }, { 0x8000, 0x7fff }, { 0x8000, 0x7fff }, { 0, 1 }, { 0, 1 }, {}, {}, {}, {}

  return {
    add_body=function(id, box)
      local function insert(len, ids, vals, minmaxs, spans, id, val, minmax)
        ids[len+1], vals[len+1], minmaxs[len+1] = ids[len], vals[len], minmaxs[len]
        local idx, prev_id, cid, pidx = len
        while vals[idx-1]>val do
          pidx = idx-1
          prev_id = ids[pidx]
          cid = shl(min(id, prev_id), 8)+max(id, prev_id)
          count[cid] = (count[cid] and count[cid] or 0) + (minmaxs[pidx]-minmax)
          cand[cid] = count[cid]==2 and true or nil
          ids[idx], vals[idx], minmaxs[idx], spans[prev_id*2+minmaxs[pidx]] =
            ids[pidx], vals[pidx], minmaxs[pidx], idx
          idx -= 1
        end
        ids[idx], vals[idx], minmaxs[idx], spans[id*2+minmax] = id, val, minmax, idx
      end

      insert(nump, x_id, x_val, x_minmax, x_spans, id, box.x1, 0)
      insert(nump+1, x_id, x_val, x_minmax, x_spans, id, box.x2, 1)
      insert(nump, y_id, y_val, y_minmax, y_spans, id, box.y1, 0)
      insert(nump+1, y_id, y_val, y_minmax, y_spans, id, box.y2, 1)
      nump += 2
    end,
    remove_body=function(id)
      local function remove(len, ids, vals, minmaxs, spans, idx)
        for i=idx+1, len do
          if (ids[i]>0) spans[ids[i]*2+minmaxs[i]] = i-1
          ids[i-1], vals[i-1], minmaxs[i-1] = ids[i], vals[i], minmaxs[i]
        end
      end
      remove(nump, x_id, x_val, x_minmax, x_spans, x_spans[id*2])
      remove(nump-1, x_id, x_val, x_minmax, x_spans, x_spans[id*2+1])
      remove(nump, y_id, y_val, y_minmax, y_spans, y_spans[id*2])
      remove(nump-1, y_id, y_val, y_minmax, y_spans, y_spans[id*2+1])
      nump -= 2

      local id1, id2 = shl(id, 8), id
      for cid in pairs(count) do
        if (band(cid, 0xff00)==id1 or band(cid, 0x00ff)==id2) count[cid] = nil
      end
      for cid in pairs(cand) do
        if (band(cid, 0xff00)==id1 or band(cid, 0x00ff)==id2) cand[cid] = nil
      end
    end,
    update_body=function(id, box)
      local function update(ids, vals, minmaxs, spans, idx, val)
        local off, id1, id2, cid, nidx
        vals[idx] = val
        while mid(vals[idx-1], val, vals[idx+1])!=val do
          off = vals[idx+1]<val and 1 or -1
          nidx = idx+off
          id1, id2 = ids[idx], ids[nidx]
          if id1!=id2 then
            cid = shl(min(id1, id2), 8)+max(id1, id2)
            count[cid] = (count[cid] and count[cid] or 0) - off*(minmaxs[nidx]-minmaxs[idx])
            cand[cid] = count[cid]==2 and true or nil
          end

          ids[idx], vals[idx], minmaxs[idx], spans[id1*2+minmaxs[idx]],
            ids[nidx], vals[nidx], minmaxs[nidx], spans[id2*2+minmaxs[nidx]] =
            ids[nidx], vals[nidx], minmaxs[nidx], nidx,
            ids[idx], vals[idx], minmaxs[idx], idx
          idx += off
        end
      end
      update(x_id, x_val, x_minmax, x_spans, x_spans[id*2], box.x1)
      update(x_id, x_val, x_minmax, x_spans, x_spans[id*2+1], box.x2)
      update(y_id, y_val, y_minmax, y_spans, y_spans[id*2], box.y1)
      update(y_id, y_val, y_minmax, y_spans, y_spans[id*2+1], box.y2)
    end,
    has_more=function() iter = next(cand, iter) return iter end,
    next=function() if(iter) return shr(band(iter, 0xff00), 8), band(iter, 0xff) end
  }
end
-- geometry
--[[
geometry for collision detection, uses SAT for collisions
]]
-- convex geometry collider
function circles_collide(x1, y1, r1, x2, y2, r2)
 local x,y,r,dist,rsq,cid,cx,cy,nx,ny,a=x1-x2,y1-y2,r1+r2
 dist,rsq=(x*x)+(y*y),r*r
 if dist > rsq then
  return nil
 end
 a=atan2(x,y)
 nx,ny=cos(a+0.5),sin(a+0.5)
 cx,cy=x1+(nx*r1),y1+(ny*r1)
 return -1, abs(rsq-dist)/2, -nx, -ny, cx, cy, cx, cy
end

function geometry(numv, vx, vy, r)
  local tvx, tvy, nx, ny, tnx, tny, maxp, box, x, y, len, idx = {}, {}, {}, {}, {}, {}, {}, aabb()

  for i=1,numv do
    idx, x, y =  i%numv+1, vx[i], vy[i]
    tvx[i], tvy[i], nx[i], ny[i] = x, y, y-vy[idx], vx[idx]-x
    len = sqrt(nx[i]^2+ny[i]^2)
    nx[i] /= len ny[i] /= len
  end

  return {
    numv=numv,
    x=tvx, y=tvy,
    nx=tnx, ny=tny,
    maxp=maxp,
    aabb=box,
    r=r,
    collides=function(g)
      local function sat(nv1, x1, y1, nx1, ny1, maxp, nv2, x2, y2, nx2, ny2)
        local cid, dist, nrmx, nrmy, rx, ry, minp, p, idx, d,
          px, py, p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y, p1, p2, p3, p4,
          lidx, ridx, ldot, rdot, ex, ey, minn, maxn, mine, maxe, alpha = -1, 0x7fff
        for i=1,nv1 do
          minp, idx = 0x7fff, -1
          for j=1,nv2 do
            p = x2[j]*nx1[i]+y2[j]*ny1[i]
            if (p<minp) minp, idx, px, py = p, j, x2[j], y2[j]
          end

          if (minp>maxp[i]) return nil

          d = maxp[i]-minp
          if d<dist then
            dist, nrmx, nrmy = d, nx1[i], ny1[i]

            lidx, ridx = (idx-2)%nv2+1, idx
            ldot, rdot = nx2[lidx]*nx1[i]+ny2[lidx]*ny1[i],
                         nx2[ridx]*nx1[i]+ny2[ridx]*ny1[i]

            if min(ldot, rdot)<0xffff.0008 then
              idx = ldot<rdot and lidx or ridx
              ex, ey, p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y =
                -ny2[idx], nx2[idx],
                x1[i], y1[i], x1[i%nv1+1], y1[i%nv1+1],
                x2[idx], y2[idx], x2[idx%nv2+1], y2[idx%nv2+1]
              p1, p2, p3, p4 =
                ex*(p1x-px)+ey*(p1y-py), ex*(p2x-px)+ey*(p2y-py),
                ex*(p3x-px)+ey*(p3y-py), ex*(p4x-px)+ey*(p4y-py)

              minn, maxn = minmax(p1, p2)
              mine, maxe = minmax(p3, p4)

              alpha = 0.5*(mid(mine, minn, maxe)+mid(minn, maxe, maxn))

              cid, rx, ry = (shl(i+nv1, 8)+idx+nv2), px+alpha*ex, py+alpha*ey
            else
              cid, rx, ry = (shl(i+nv1, 8)+idx), px, py
            end
          end
        end
        return cid, dist, -nrmx, -nrmy, rx+nrmx*dist, ry+nrmy*dist, rx, ry
      end

      local id1, dist1, nx1, ny1, xA1, yA1, xB1, yB1 = sat(numv, tvx, tvy, tnx, tny, maxp, g.numv, g.x, g.y, g.nx, g.ny)
      local id2, dist2, nx2, ny2, xB2, yB2, xA2, yA2 = sat(g.numv, g.x, g.y, g.nx, g.ny, g.maxp, numv, tvx, tvy, tnx, tny)
      if (not(id1 and id2)) return nil
      if (dist1<dist2) return id1, dist1, nx1, ny1, xA1, yA1, xB1, yB1
      return id2, dist2, -nx2, -ny2, xA2, yA2, xB2, yB2
    end,
    transform=function(x, y, a)
      box.set()
      for i=1,numv do
        tvx[i], tvy[i] = transform(vx[i], vy[i], x, y, a)
        tnx[i], tny[i] = transform(nx[i], ny[i], 0, 0, a)
        maxp[i], box.x1, box.y1, box.x2, box.y2 =
          tnx[i]*tvx[i]+tny[i]*tvy[i],
          min(tvx[i], box.x1), min(tvy[i], box.y1),
          max(tvx[i], box.x2), max(tvy[i], box.y2)
      end
    end,
    draw=function(vp)
      local v1x, v1y, v2x, v2y, idx = vp.to_screen(tvx[1], tvy[1])
      for i=1,numv do
        idx = i%numv+1
        v2x, v2y = vp.to_screen(tvx[idx], tvy[idx])
        line(v1x, v1y, v2x, v2y)
        v1x, v1y = v2x, v2y
      end
    end
  }
end
--https://www.lexaloffle.com/bbs/?tid=38548
--97 tokens with Scaling and arbitrary size
function pd_rotate(x,y,rot,mx,my,w,flip,scale)
  scale=scale or 1
  w*=scale*4

  local cs, ss = cos(rot)*.125/scale,sin(rot)*.125/scale
  local sx, sy = mx+cs*-w, my+ss*-w
  local hx = flip and -w or w

  local halfw = -w
  for py=y-w, y+w do
    tline(x-hx, py, x+hx, py, sx-ss*halfw, sy+cs*halfw, cs, ss)
    halfw+=1
  end
end



dirx, diry = { -1, 1, 0, 0 }, { 0, 0, -1, 1 }

POLYGONS=7
WALL_FRICTION=9999
BODY_FRICTION=1000
WAIT_FOR_DROP_FRAMES=25

-- ball_conf indices
RADIUS,MERGE_SCORE,BALL_MASS,COLOR,COLOR_FG,BORDER_COLOR,FILL_PATTERN,BORDER_SIZE,FACE_SPRITE_X,FACE_SPRITE_Y,FACE_SPRITE_WIDTH,FACE_SPRITE_ONLY=
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,12
ball_conf = {
  -- 1. cherry
  {   4,  1,  1,  2,   2,  0, 0x0000, 1, 29.5,   1, 2, false }, 
  -- 2. strawberry
  {   5,  3,  2,  8,  14,  2, 0x50c0, 1, 27.0,   1, 2,  true },
  -- 3. grapes
  {   6,  6,  3,  13,  2,  1, 0x5555, 1, 23.0,   1, 2,  true },
  -- 4. dekopon/satsuma
  {   8, 10,  4,  9,  10,  4, 0x0000, 1, 32.0,   1, 2, false },
  -- 5. persimon (looks like an orange though)
  {   9, 15,   5,  9,  9,  4, 0x50c0, 1, 35.1, 1.2, 3, false },
  -- 6. apple
  {  11, 21,   6,  8,  8,  2, 0x0000, 1, 40.0, 1.5, 3, false },
  -- 7. pear
  {  12, 28,   7, 15, 11,  5, 0x5a5a, 1, 44.0, 1.5, 3, false },
  -- 8. peach
  {  14, 36,   8, 14,  9,  2, 0x0000, 1, 48.0, 1.5, 3, false },
  -- 9. pineapple
  {  16, 45,   9, 10, 10,  9, 0x0000, 2, 53.0, 2.3, 5, false },
  -- 10. melon/cantaloupe
  {  20, 55,  10, 11, 11,  3, 0x0000, 2, 59.0, 2.0, 5, false },
  -- 11. watermelon
  {  23, 66,  11, 11,  3,  3, 0x0000, 3, 67.0, 3.0, 5, false },
}

function _init()
  cartdata('spoike_suika_melons_1')
  high_score=dget(0)
  options=dget(1)
  debug, particles={}, {}
  update_menuitems()
  do_intro()
  --start_game()
  --do_wiki()
  --do_gameover()
end

function update_menuitems()
  menuitem(5, "reset highscore", function()
    high_score=0
    dset(0,0)
  end)
  menuitem(1, "music        "..onoff((options&0b10)==0), function()
   options=options^^0b10
   dset(1,options)
   update_menuitems()
   update_music()
  end)
  menuitem(2, "show physics "..onoff((options&0b1)>0), function()
   options=options^^0b1
   dset(1,options)
   update_menuitems()
  end)
end

function onoff(b)
 return b==true and " on" or "off"
end


function update_music()
 if options&0b10>0 then
  music(-1)
  return
 end
 if _upd==game_update or _upd==wiki_update then
  music(1)
 elseif _upd==gameover_update then
  music(12)
 else
  music(-1)
 end
end

function do_wiki()
  _upd,_drw=wiki_update,wiki_draw
  wiki_idx=current_ball or next_ball
  wiki_offs=(wiki_idx-1) * 48
  wiki_start_t,wiki_t,wiki_closing=0,1,0
end

wiki_text={
  split"cherry,a fleshy drupe of genus prunus,grown on trees that are pretty,and used for furniture",
  split"strawberry,genus fragaria from brittany,is botanically a fruit and,not a berry",
  split"grapes,grows on vines of genus vitis,is botanically a berry and,not a fruit",
  split"dekopon,seedless variety of satsumas,orange and has a protruding,bump on top",
  split"persimon,genus diospyros grow on trees,is morphologically a fruit,like a tomato",
  split"apple,fruit from tree of genus malus,that has significance in many,differentu and vast cultures",
  split"pear,fruit from tree of genus pyrus,comes in variety of shapes yet,nashi pears are very round",
  split"peach,fruit of genus prunus and is,distinguished by its crimped,seed shell",
  split"pineapple,ananas comosus is a plant with,fruits grown in a small shrub,and are used sliced on pizzas",
  split"melon,this is a cantaloupe of the,cucumis melo species & please,do avoid eating its seeds",
  split"watermelon,      the king of melons!,a berry with hard rind and is,of the cucumis lanatus species"
}

function wiki_update()
  wiki_start_t=min(wiki_start_t + 1,10)
  if wiki_closing >= 1 then
   wiki_closing+=1.5
  end
  if wiki_closing > 10 then
   _upd,_drw=game_update,game_draw
  end
  if wiki_t < 1 then
   wiki_t = min(1, 0.2+wiki_t)
   wiki_offs=lerp(wiki_start_offs, wiki_target_offs, wiki_t)
  end
  if btnp(1) then
   wiki_idx=min(#wiki_text, wiki_idx+1)
   wiki_start_offs=wiki_offs
   wiki_target_offs=(wiki_idx-1) * 48
   wiki_t=0
   sfx(3)
  end
  if btnp(0) then
   wiki_idx=max(1, wiki_idx-1)
   wiki_start_offs=wiki_offs
   wiki_target_offs=(wiki_idx-1) * 48
   wiki_t=0
   sfx(3)
  end

  if btnp(4) or btnp(5) then
   sfx(5)
   wiki_closing=1
  end
end

function wiki_draw()
  game_draw()

  camera(0, lerp(-80, 0, (wiki_start_t-wiki_closing)/10))
  for i=0,127 do
   line(i, 64+(sin((t()/2)+(i/73))*4.5), i, 127, 9)
   line(i, 70+(sin((t()/2)+((i/100+0.33)))*2.5), i, 127, 4)
  end

  circfill(
    64,
    64,
    sin(t()*0.75)*2+ball_conf[wiki_idx][RADIUS]+4,
    10
  )
  for i=1,#wiki_text do
    draw_ball(i, 64+((i-1) * 48)-wiki_offs, 64)
  end

  local b = ball_conf[wiki_idx]
  print_sc(wiki_text[wiki_idx][1], 80, b[COLOR], 1, true)
  local text = wiki_text[wiki_idx]
  for i=2,#text do
    print(wiki_text[wiki_idx][i], 4, 90+(8*(i-2)), 1)
  end
  if wiki_t == 1 and blink(2) then
    if wiki_idx > 1 then
      spr(2,34,60)
    end
    if wiki_idx < #wiki_text then
      spr(3,127-42,60)
    end
  end
  if wiki_idx < #wiki_text then
   print('merges to:', 4, 118, 1)
   local next_idx = wiki_idx+1
   print_s(wiki_text[next_idx][1], 46, 118, ball_conf[next_idx][COLOR], 1, true)
  else
   print('magically poofs when merged', 4, 118, 1)
  end
  camera()
end

function _draw()
  _drw()

  for i,l in pairs(debug) do
   print(l,0,(i-1)*7,7)
  end

  for p in all(particles) do
   p:draw()
  end

  --print("∧"..flr(stat(1)*100)/100,1,1,2)
end

function do_intro()
  --music(0)
  fruit_particles,_drw,_upd,intro_to_start={},intro_draw,intro_update,0
  for i=1,20 do
    create_fruit_particle() 
  end
end

function create_fruit_particle()
  local a = rnd(1)
  add(fruit_particles, {
    sx=a>0.5 and -64 or 192,
    sy=32+rnd(64),
    dx=a>0.5 and 192 or -64,
    dy=32+rnd(64),
    t=rnd(100)-100,
    tend=100,
    idx=ceil(rnd(10)),
    update=update_fruit_particle,
    draw=draw_fruit_particle
  })
end

function update_fruit_particle(p)
 p.t+=1
 if p.t > p.tend then
  del(fruit_particles, p)
  create_fruit_particle()
 end
end

function draw_fruit_particle(p)
  local t = p.t/p.tend
  draw_ball(p.idx,
   lerp(p.sx,p.dx,t),
   lerp(p.sy,p.dy,t))
end

function intro_draw()
  cls(15)
  for i=0,127 do
   line(i,0,i,sin(t()+(i*0.01)+0.3)*3+20,14)
   line(i,0,i,sin(t()+(i*0.005))*-5+10,9)
   line(i,128,i,128-(sin(t()+(i*0.01)+0.3)*3+20)+lerp(0,-128,intro_to_start/10),14)
   line(i,128,i,128-(sin(t()+(i*0.005))*5+10)+lerp(0,-128,intro_to_start/15),9)
   line(i,128,i,128-(sin(t()+(i*0.0025))*5+10)+lerp(20,-128,intro_to_start/28),15)
  end
  camera(0, lerp(0, -128, intro_to_start/10))
  for p in all(fruit_particles) do
   p:draw()
  end
  camera(0, lerp(0, 64, intro_to_start/30))
  sspr(0,64,57,10,8,10,114,20)
  print_sc("watermelon game", 32, 9, 4, true)
  print_sc("pico8 demake", 40, 9, 4, true)
  camera(0, min(0, lerp(64, -128, intro_to_start/25)))
  draw_ball(11, 64, 70+(sin(t()*0.25)*3.5))
  camera()
  if blink() and intro_to_start == 0 then
   camera(4,0)
   print_sc("press 🅾️ or ❎ to start", 104, 7, 3, true)
   camera()
  end
end

function intro_update()
  for p in all(fruit_particles) do
   p:update()
  end
  if intro_to_start==30 then
   start_game()
  elseif intro_to_start>0 then
   intro_to_start+=1
  elseif btnp() > 0 then
    intro_to_start=1
    sfx(2)
  end
end

function do_gameover()
  got_highscore = score > high_score
  if got_highscore then
   dset(0, score)
  end
  go_timer=0
  _drw,_upd=gameover_draw,gameover_update
  update_music()
end

function gameover_update()
  if go_timer < 50 then
    go_timer+=1
  elseif btnp(4) or btnp(5) then
    if got_highscore then
      high_score = score
    end
    sfx(2)
    do_intro()
  end
end

function gameover_draw()
 game_draw()
 clip(lerp(128, 0, min(go_timer/10, 1)), 0, 128, 128)
 rectfill(0, 46, 128, 90, 4)
 line(0, 91, 128, 91, 2)
 print_sc(got_highscore and 'you got highscore!' or 'game over', 53, got_highscore and 10 or 7, 1)
 print_sc(score, 61, got_highscore and 10 or 7, 1)
 print_sc('previous best', 71, 7, 2)
 print_sc(high_score, 79, 7, 2)
 clip()

 if go_timer == 50 and blink() then
  print_sc('click to continue', 100, 7, 4, true)
 end
end

fade_palettes={
  {15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15},
  { 9, 9, 9, 9,15, 15,10,15,15,15,15,15,15,15,15, 9},
  { 2, 2, 4, 4, 9, 15,10, 9, 9, 9, 9, 9, 9, 9,15, 2},
}

function game_draw()
  cls(15)
  if game_intro_t < 10 then
   pal(fade_palettes[flr(lerp(1,#fade_palettes+1,game_intro_t/10))])
  else
   pal()
  end
  for i=0,15 do
   map(11, 0, i*8, 0, 1, 16)
  end

  -- the jar
  map(0, 0, 3, 13, 11, 16)

  -- next ball
  map(12, 0, 94, 2, 4, 6)
  print_s("next", 102, 6, 15, 1)
  draw_ball(next_ball, 109, 25)

  -- drop cursor
  local psx, psy = vp.to_screen(px, 0)
  line(psx, 9, psx, 123, 7)
  sspr(96,32,24,16,psx-2,2)

  if current_ball and cursor_wait_timer == 0 then
   draw_ball(current_ball, psx, psy)
  end

  for id in all(ball_ids) do
   local idx = balls[id]
   local x,y,a = s.position(id)
   local px, py = vp.to_screen(x,y)
   draw_ball(idx, px, py, a, id == highlight_fruit)
  end

  line(3,28,90,28,4)

  map(17, 0, 94, 44, 5, 7)
  print_s("score", 99, 51, 15, 1)
  print_s(score, 99, 59, 15, 1)

  print_s("best", 99, 71, 15, 1)
  print_s(high_score, 99, 78, 15, 1)

  -- debug draw physics bodies
  if options&0b1 > 0 then
    s.draw(vp)
  end

  print_s("🅾️ drop",95,110,15,4,true)
  print_s("❎ wiki",95,119,15,4,true)
end

function _update()
  _upd()
  for p in all(particles) do
   p:update()
  end
end

function game_update()
  if game_intro_t < 20 then
   game_intro_t+=1
  end
  for id in all(ball_ids) do
   local x,y,a = s.position(id)
   if y > 0 then
    highlight_fruit = id
    do_gameover()
    return
   end
  end
  s.update()

  for i = 0, 1 do
    if btn(i) then
      pdx = mid(-0.9,pdx+(dirx[i+1]*0.15),0.9)
    end
  end
  pdx*=0.75
  local min_x, max_x = -3, 3
  px = mid(-3.5, px+pdx, 3.45)

  if btnp(5) then
   sfx(4)
   do_wiki()
  end

  if btnp(4) and cursor_wait_timer == 0 then
    --drop da ball
    cursor_wait_timer = WAIT_FOR_DROP_FRAMES
    add_ball_body(px,0,current_ball)
    current_ball=nil
    sfx(0)
  end

  if cursor_wait_timer == 1 then
    create_new_balls()
  end

  for c in all(to_add) do
    add_ball_body(c.x,c.y,c.idx)
  end
  if #to_add > 0 then
   sfx(1)
  end
  to_add={}

  cursor_wait_timer = max(0, cursor_wait_timer-1)
end

function start_game()
  _drw,_upd=game_draw,game_update
  px, pdx, cursor_wait_timer, score, highlight_fruit, game_intro_t = 0, 0, 0, 0, nil, 0
  bag_of_balls, balls, ball_ids, to_add = add_balls_to_bag{}, {}, {}, {}
  update_music()
  create_new_balls()
  vp = viewport{ scale=10 }
  vp.translate(-1.7, 4.7)
  s = scene{
    size = 13, -- size of simulation area
    g = -9.8, --gravity, default -9.8
    damp = 0x0.ffe0, -- damping, default 1
    slop = 0x0.00f,--0x0.08, -- allowed overlap before collision response, default 0x0.08
    sframes = 100, -- frames before bodies are put to sleep, default 100
    --svelocity = 0x4, -- velocity diff for sleep default 0x0.4
    beta = 0.2, -- proportion of positional correction, default 0.2
    isteps = 10 -- solver steps, default 4
  }
  s.add_body{ x=0, y=-11.6, mass=0, moi=0, rest=0.0, frict=WALL_FRICTION, verts=rectangle(14, 2) }
  s.add_body{ x=-5.2, y=-6, mass=0, moi=0, rest=0.0, frict=WALL_FRICTION, verts=rectangle(2, 14) }
  s.add_body{ x=5.2, y=-6, mass=0, moi=0, rest=0.0, frict=WALL_FRICTION, verts=rectangle(2, 14) }
  
  -- test balls
  --add_ball_body(0, -1, 10)
  --add_ball_body(0, -10, 11)

  -- stress test
  --[[
  for x=-3,3,2 do
    for y=3,6,2 do
     add_ball_body(x, -y*2, rnd({1,2,3,4,5,6,7,8,9}))
     --add_ball_body(x, -y*2, rnd({1,2,3,4}))--,5,6,7,8,9}))
    end
  end
  ]]
end

function create_new_balls()
  if #bag_of_balls < 3 then
   bag_of_balls = add_balls_to_bag(bag_of_balls)
  end
  current_ball = next_ball
  next_ball = deli(bag_of_balls, 1)
  if current_ball == nil then
    current_ball = deli(bag_of_balls, 1)
  end
end

listener = {
  on_event=function(args)
    -- ON_BODY_DEAD
    if args.event==0x05 then
     remove_ball_body(args.id, true)
     return
    end
    -- ON_COLLISION_ENTER
    if args.event==0x01 then
     local px, py = vp.to_screen(args.x, args.y)
      --[[
      local function draw_contact(id,col)
        local x, y = s.position(id)
        local px, py = vp.to_screen(x, y)
        circfill(px, py, 3, col) 
      end
      draw_contact(args.id, 0)
      draw_contact(args.body, 1)
      circfill(px, py, 3, 8)
      color(0)
      stop(args.dist)
      ]]

     local b1 = balls[args.id]
     local b2 = balls[args.body]
     if b1 == b2 and b1 != nil and b2 != nil then
      add_boom_particle(args.id, b1)
      add_boom_particle(args.body, b2)
      local conf = ball_conf[b1]
      add_particles(px, py, 50, {conf[COLOR], conf[COLOR_FG], conf[BORDER_COLOR]})
      s.remove_body(args.id)
      s.remove_body(args.body)
      score += conf[MERGE_SCORE]
      local idx = b1 + 1
      if idx <= #ball_conf then
        local radius = ball_conf[idx][RADIUS]
        if radius > 0 then
          add(to_add, {x=args.x, y=args.y, radius=radius, idx=idx})
        end
      end
     end
    end
  end
}

function draw_ball(ball_idx, x, y, angle, is_highlighted)
  if angle == nil then angle = 0 end
  local ball = ball_conf[ball_idx]
  local c = (ball[COLOR_FG] << 4) | ball[COLOR]
  if is_highlighted then
    circfill(x, y, ball[RADIUS]+4+(sin(t()*0.8)*2), 7)
  end
  if ball[FACE_SPRITE_ONLY] == false then
    circfill(
      x,
      y,
      ball[RADIUS]-1,
      ball[BORDER_COLOR]
    )
    fillp(ball[FILL_PATTERN])
    circfill(
      x,
      y,
      ball[RADIUS]-1-ball[BORDER_SIZE],
      c 
    )
    fillp()
  end
  palt(0x0008)
  pd_rotate(x, y, -angle, ball[FACE_SPRITE_X], ball[FACE_SPRITE_Y], ball[FACE_SPRITE_WIDTH], false, 1)
  palt()
end

bottom_y = 119

function add_ball_body(x,y,idx)
  local i = s.add_body({
    x=x,
    y=y,
    mass=1,--ball_conf[idx][BALL_MASS]/10, -- mass, default 1
    moi=nil, --inertia, default depends on mass
    rest=0.15, --restitution, default 0.1
    frict=BODY_FRICTION, -- friction, default 1
    verts=ngon((ball_conf[idx][RADIUS] / 10), 5),
    listener=listener
  })
  balls[i] = idx
  add(ball_ids, i)
end

function remove_ball_body(id)
 balls[id] = nil
 del(ball_ids, id)
end

function draw_particle(p)
 circfill(p.x,p.y,p.r,p.col)
end

function update_particle(p)
 p.x+=p.dx
 p.y+=p.dy
 p.life-=1
 p.dy+=0.25
 if p.life < 0 then
  del(particles, p)
 end
end

function add_particles(x, y, amt, cols)
 amt = amt or 20
 cols = cols or {1,2,3}
 for i=1,amt do
  add(particles, {
    x=x,y=y,
    dx=rnd(10)-5,
    dy=rnd(10)-5,
    r=rnd(1)+0.5,
    col=rnd(cols),
    life=18,
    update=update_particle,
    draw=draw_particle
  })
 end
end

function add_boom_particle(id, ballidx)
 local x, y = s.position(id)
 local sx, sy = vp.to_screen(x, y)
 add(particles, {
   x=sx,y=sy,
   r=ball_conf[ballidx][RADIUS] + 2,
   t=0,
   draw=draw_boom_particle,
   update=update_boom_particle
 })
end

function draw_boom_particle(p)
 circfill(p.x,p.y,lerp(p.r,0,p.t),7)
end

function update_boom_particle(p)
  p.t+=0.1
  if p.t > 1 then
   del(particles, p)
  end
end

function print_s(str, x, y, colfg, colbg, do_halo)
 if do_halo then
  for i=1,4 do
   print(str, dirx[i]+x, diry[i]+y, colbg)
  end
 else
  print(str, x+1, y+1, colbg)
 end
 print(str, x, y, colfg)
end

function print_sc(str, y, colfg, colbg, do_halo)
 str=tostr(str)
 print_s(str, 64-(#str*2), y, colfg, colbg, do_halo)
end

function lerp(a,b,t)
 return (1-t)*a+t*b
end

function shuffle(t)
 -- fisher-yates
 for i=#t,1,-1 do
  local j=flr(rnd(i)) + 1
  t[i],t[j] = t[j],t[i]
 end
 return t
end

function blink(speed)
  speed = speed or 1
  return flr(t()*speed) % 2 == 1 
end

function add_balls_to_bag(bag)
  local initial_bag=shuffle{1,1,2,2,3,3,4,4,5}
  for i in all(initial_bag) do
   add(bag, i)
  end
  return bag
end


__gfx__
0000000077777760000020000002000000444444444444444444420000000000ffffffff00000000400000022222222220000004000000044000000040000000
00000000077776000002222222222000044fffffffffffffffff442000000000ffffffff00000000400000222222222222000004000000400400000004000000
0070070000776000002277722777220044f11212222222222222f44200000000ffffffff00000000400002222222222222200004000004000040000000400000
000770000006000002277772277772204f1244444444444444444f4200000000ffffffff00000000400022222222222222220004000040000004000000040000
000770000000000000227772277722004f1444444444444444444f4200000000ffffffff00000000400222222222222222222004000400000000400000004000
007007000000000000022222222220004f2444444444444444444f4200000000ffffffff00000000402222222222222222222204004000000000040000000400
000000000000000000002000000200004f1444444444444444444f4200000000ffffffff00000000422222222222222222222224040000000000004000000040
000000000000000000000000000000004f2444444444444444444f4200000000ffffffff00000000444444444444444444444444444444444444444400000004
ffffffffffffffffffffffffffffffff4f2444444444444444444f4200000000ffffffff00000000400000000000000000000400400000044000000400000004
fffffffff0ffffffffffff0ff0ffff0f4f2444444444444444444f4200000000f9f9f9f900000000400000000000000000000400400000400400000400000040
f0ffff0fff0fff0ff0fff0ffff0ff0ff4f2444444444444444444f4200000000ffffffff00000000400000000000000000000400400004000040000400000400
fffffffff0ffffffffffff0ff0ffff0f4f2444444444444444444f42000000009f9f9f9f00000000400000000000000000000400400040000004000400004000
ffffffffffffffffffffffffffffffff4f2444444444444444444f4200000000ffffffff00000000400000000000000000000400400400000000400400040000
f0ffff0ffff00ffffff00ffffff00fff4f2444444444444444444f4200000000f9f9f9f900000000400000000000000000000400404000000000040400400000
ff0000ffffffffffffffffffffffffff4f2444444444444444444f42000000009f9f9f9f00000000400000000000000000000400440000000000004404000000
ffffffffffffffffffffffffffffffff4f2444444444444444444f4200000000f9f9f9f900000000400000000000000000000400444444444444444440000000
ffffffffffffffff00000000000000004f2444444444444444444f42000000009f9f9f9f00000000400000000000000000000400400000000000000400000000
fffffffff77ff77f00000000000000004f2444444444444444444f4100000000f9f9f9f900000000400000000000000000000400400000000000000400000000
ff0ff0ff707ff70700000000000000004f2444444444444444444f42000000009999999900000000400000000000000000000400400000000000000400000000
ffffffff777ff77700000000000000004f2444444444444444444f41000000009f9f9f9f00000000400000000000000000000400400000000000000400000000
ff0ff0ffffffffff000000000000000044f44444444444444444f441000000009999999900000000400000000000000000000400400000000000000400000000
fff00ffff7ffff7f0000000000000000044fffffffffffffffff441200000000f9f9f9f900000000400000000000000000000400400000000000000400000000
ffffffffff7777ff0000000000000000004444444444444444444120000000009999999900000000400000000000000000000400400000000000000400000000
ffffffffffffffff0000000000000000000222222222222221211200000000009999999900000000400000000000000000000400400000000000000444444444
ffffffff000000000000000000000000000000000000000000000000000000009999999900000000400000000000000000000400400000000000000400000000
ffffffff000000000000000000000000000000000000000000000000000000009999999900000000044444444444444444444000400000000000000400000000
ffffffff000000000000000000000000000000000000000000000000000000009999999900000000000000000000000000000000400000000000000400000000
ff0ff0ff000000000000000000000000000000000000000000000000000000009999999900000000000000000000000000000000400000000000000400000000
ffffffff000000000000000000000000000000000000000000000000000000009999999900000000000000000000000000000000400000000000000400000000
fff00fff000000000000000000000000000000000000000000000000000000009999999900000000000000000000000000000000400000000000000400000000
ffffffff000000000000000000000000000000000000000000000000000000009999999900000000000000000000000000000000400000000000000400000000
ffffffff000000000000000000000000000000000000000000000000000000009999999900000000000000000000000000000000444444444444444400000000
cccccc333ccccccccccccccccccccccccccccccccccccccccccccccc44ccccccccccccccc0ccccccccccccc33ccccccc000000000999999000000000cccccccc
ccccc3bbb3cccccccccccccccccccccb3ccccccccccccbb3ccccccc400cccccccccccccc0cccccccc3333c3bb3c3333c000000099777777990000000cccccccc
ccc11113b3111ccccccccccccccccccb3ccccccccccc3333ccccccc40ccccccccccccccc0ccccccccc3bb3bbbb3bb3cc000000977777777779000000cccccccc
cc17dd11311dd1cccccccccccccbb3333bbccccccccc3cccccccccc4022ccccccccccccc055cccccccc3333333333ccc000099977777777779990000cccccccc
c17dddd111d7dd1ccccccccccccc3bb3233ccccccccc3cccccccccccccccccccccccffcccccccccccccccccccccccccc000977777777777777779000cccccccc
c1dddddddddddd1cccccccccccc2e88e88e2cccccccc3cccccccc7cccccccccccccffffccccccccccccccccccccccccc009777777777777777777900cccccccc
c11ddddddddddd1cccccccccccc280888082ccccccceccccccccc2ccccccccccccffffffcccccccccccccccccccccccc009777777777777777777900cccccccc
cc11d0ddddd0d1ccccccccccccc2e8e88e82cccccceccccccc77cccccccccccccccffffccccccccccccccccccccccccc097977757777775777779790cccccccc
c17ddd0ddd0ddd1cccccccccccc288000882cccccccccccccc77ccccccccccccffccffcccccccccccc44ccccccccc44c97777ee77577577ee7777779cccccccc
c1dddddddddddd1cccccccccccc2e80708e2ccccccccccccccccccccccccccccfffcc55cccc55ccccccc4ccccccc4ccc977777777755777777777779cccccccc
cc1dddd000ddd1cccccccccccccc2880e82ccccccccccccccccc22cccc22cccccffcc55cccc55ccccccccccccccccccc977777777777777777777779cccccccc
cc1dddd0e0ddd1ccccccccccccccc2e882cccccccccccccccccc22cccc22ccccccccccccccccccccccccc4cc4cc4cccc977777777777777777777779cccccccc
ccc1dddddddd1ccccccccccccccccc222cccccccccccccccccccccc22ccccccccccccccccccccccccccccc44744ccccc097777777777777777777790cccccccc
cccc11111111cccccccccccccccccccccccccccccccccccccccccc2772cccccccccccc5c55c5cccccccccc47774ccccc009977779777777977779900cccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc2222ccccccccccccc5775cccccccccccc444cccccc000099990999999099990000cccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc55cccccccccccccccccccccc000000000000000000000000cccccccc
cccccc44444ccccccccccccb3ccccccccccccccccccccccccccccfffc22cccccccacccacccacccaccccccccccccccccccccccccccccccccccccccccccccccccc
ccccc4a9a9a4cccccccccc3b33cccccccccccccccccccccccccffccc2cccccccccaccaccccaccacccccccccccccccccccccccccccccccccccccccccccccccccc
cccc44aaaaa44ccccccc3b333b33ccccccccccccccccccaccffcccc2cccccccccacaacaccacaaccc9cccccc99ccccccccccccccccccccccccccccccccccccccc
cccc4aaaa99a4cccccccc33cc33ccccccccccccccccccccaccccccc2ccccccccaccccccaacccacccc9cccc9cc9cccccccccccccccccccccccccccccccccccccc
ccccaaaaaaaaacccccccc3cccc3ccccccccccccccccccccacccccccccccccccccccccacccccccacccc9cc9cccc9ccccccccccccccccccccccccccccccccccccc
cccaaaaaaaaaaaccccccaaccccccccccccccccccccccccacccccccccccccccccccaccaccccccccccccc99cccccc9cccccccccccccccccccccccccccccccccccc
ccaa44aaaaa44faccccaacccccccccccccccccccccccaacccccccccccccccccccccaaccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cca4774aaa4774ccccccccccccccccccccccccccccacccacccccccccccccccccccacccaccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cca4774aaf4774acccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccaa44aafaf44acccccc00cccc00ccccccccccccccccccccc22cccccccccc22cc33cccccccccc33ccccccccccccccccccccccccccccccccccccccccccccccccc
ccaaaaa4444faccccccc00cccc00ccccccccccccccccc7cc2222cccccccc22223333cccccccc3333ccccccc9cccccccccccccccccccccccccccccccccccccccc
cccaaaf4774acccccccccccccccccccccccccccccccc7ccc2222cc2c2c2c22223333cccccccc3333cccccc9ccccccccccccccccccccccccccccccccccccccccc
cccaafa4444cccccccccc4c44c4cccccccccccccccc7ccccc22cccc272ccc22cc33cccccccccc33cccccc9cccccccccccccccccccccccccccccccccccccccccc
cccccac4ca4ccccccccccc4cc4cccccccccccccccc7cccccccccccc272cccccccccccccc3ccccccccccc9ccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc77cccccccccccccc2ccccccccccccc33c33ccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
04444444400000004400004400000004440044040000000000440000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
49999999940000449940449944440004994449494000000004994000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
49999999940044999944999999994049999949494000000004994000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
04444999404499999404999999999449949999940444440049994000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
00049994049999994000449944499404404994404999994049940044000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
00499994049944994000049940499400004994004999994499944499400000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
04999499404404994000049940499400049994000444440499999999400000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
49994049940004994000049940499400049940000000000499999999400000000000000000000000cccccccccccccccccccc333333333ccccccccccccccccccc
49940004940004994000049940044000049940000000000049944499400000000000000000000000cccccccccccccccc33333333333333333333cccccccccccc
04400000400000440000004400000000004400000000000004400044000000000000000000000000ccccccccccc33333333333333333333337773ccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccc333333333333333333333333777773333ccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc3333333333333333333333333377777733333ccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc3333333333333333333333333377777733333ccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccccccccc77777c3333ccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccccccccccc77ccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccccccccccccc77ccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccccccccccccc77ccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccc3333333333333333333333333333333c3cccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc33333333333333333333333333333333b3b3ccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc33333333333333333333333333333333333b3b3cccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc333333333333333333333333333333333333b3bcccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc33333333330333333333333333003333333b3b3cccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc333333333330333333333333300003333333b3bcccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccc0cccccccccccc0000cccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccc0ccccc0ccc0cccc00ccccccccbcccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccc0ccccccc0c0cccccccccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccc0ccccccccccccccccbcccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccbcbcccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc33333ccccccccccccccccccccccccccccccb3b3cccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc3333333333333333333333333333333333b3b3bcccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc333333333333333333333333333333333b3b3b3cccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc33333333333333333333333333333333b3b3b3ccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc33333333333333333333333333333b3b3bccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccc33333333333333333333333b3b3c3ccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccccccccccccbcbccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccbcbcccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccccccccccccbccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccbcbcccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccc3333333333333333333333b3b3b3cccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccc3333333333333333333b3b3b3b3ccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccc3333333333333333b3b3b33ccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccb3b3b3b3b3b333ccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccbcbcb3333ccccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc
__label__
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
9999999999999999999999999999999999999999999eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee99999999999999999999999999999999999999999999
9999999999999999999999999999999999eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee9999999999999999999999999999999999
999999999999999999999999999eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee999999999999999999999999999
99999999999999999999eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee99999999999999999999
99999999994444444444444444eeeeeeeeeeeeee4444eeeeeeee4444eeeeeeeeeeeeee444444eeee4444ee44eeeeeeeeeeeeeeeeeeee4444ee99999999999999
9999999eee4444444444444444eeeeeeeeeeeeee4444eeeeeeee4444eeeeeeeeeeeeee444444eeee4444ee44eeeeeeeeeeeeeeeeeeee4444eeeeeeee99999999
9eeeeeee44999999999999999944eeeeeeee4444999944ee4444999944444444eeeeee44999944444499449944eeeeeeeeeeeeeeee44999944eeeeeeeeeeeee9
eeeeeeee44999999999999999944eeeeeeee4444999944ee4444999944444444eeeeee44999944444499449944eeeeeeeeeeeeeeee44999944eeeeeeeeeeeeee
eeeeeeee44999999999999999944eeee4444999999994444999999999999999944ee4499999999994499449944eeeeeeeeeeeeeeee44999944eeeeeeeeeeeeee
eeeeeeee44999999999999999944eeee4444999999994444999999999999999944ee4499999999994499449944eeeeeeeeeeeeeeee44999944eeeeeeeeeeeeee
eeeeeeeeee4444444499999944ee4444999999999944ee449999999999999999994444999944999999999944ee4444444444eeee4499999944eeeeeeeeeeeeee
eeeeeeeeee4444444499999944ee4444999999999944ee449999999999999999994444999944999999999944ee4444444444eeee4499999944eeeeeeeeeeeeee
eeeeeeeeeeeeee4499999944ee4499999999999944ffffff44449999444444999944ee4444ee4499994444ee44999999999944ee44999944eeee4444eeeeeeee
eeeeeeeeeeeeee4499999944ee4499999999999944ffffff44449999444444999944ff4444ee4499994444ee44999999999944ee44999944eeee4444eeeeeeee
eeeeeeeeeeee449999999944ee4499994444999944ffffffff44999944ff44999944ffffffff44999944eeee4499999999994444999999444444999944eeeeef
eeeeeeeeeeee449999999944ff4499994444999944ffffffff44999944ff44999944ffffffff44999944eeee4499999999994444999999444444999944ffffff
eeeeeeeeee4499999944999944ff4444ff44999944ffffffff44999944ff44999944ffffff4499999944fffffe4444444444ee44999999999999999944ffffff
ffffffffff4499999944999944ff4444ff44999944ffffffff44999944ff44999944ffffff4499999944ffffff4444444444ff44999999999999999944ffffff
ffffffff4499999944ff44999944ffffff44999944ffffffff44999944ff44999944ffffff44999944ffffffffffffffffffff44999999999999999944ffffff
ffffffff4499999944ff44999944ffffff44999944ffffffff44999944ff44999944ffffff44999944ffffffffffffffffffff44999999999999999944ffffff
ffffffff44999944ffffff449944ffffff44999944ffffffff44999944ffff4444ffffffff44999944ffffffffffffffffffffff449999444444999944ffffff
ffffffff44999944ffffff449944ffffff44999944ffffffff44999944ffff4444ffffffff44999944ffffffffffffffffffffff449999444444999944ffffff
ffffffffff4444ffffffffff44ffffffffff4444ffffffffffff4444ffffffffffffffffffff4444ffffffffffffffffffffffffff4444ffffff4444ffffffff
ffffffffff4444ffffffffff44ffffffffff4444ffffffffffff4444ffffffffffffffffffff4444ffffffffffffffffffffffffff4444ffffff4444ffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffff4f4f444f444f444f444f444f444f4ffff44f44fffffff44f444f444f444fffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffff4949499949994999499949994999494ff4994994fffff4994999499949994ffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffff4949494944944944494949994944494f494949494fff4944494949994944fffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffff4949499944944994499449494994494f494949494fff4944499949494994fffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffff49994949449449444949494949444944494949494fff4949494949494944fffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffff49994949449449994949494949994999499449494fff49994949494949994ffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffff444f4f4ff4ff444f4f4f4f4f444f444f44ff4f4fffff444f4f4f4f4f444fffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffff444f444ff44ff44f444fffff44ff444f444f444f4f4f444fffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffff499949994499449949994fff4994499949994999494949994ffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffff494944944944494949494fff494949444999494949494944fffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffff49994494494f494949994fff494949944949499949944994fffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffff4944f4944944494949494fff494949444949494949494944fffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffff494f49994499499449994fff4999499949494949494949994ffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffff4fff444ff44f44ff444f33333333344f4f4f4f4f4f4f444fffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffff333333333333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff333333333333333333333fffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffff3333333bbbbbbbbb3333333ffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffff333333bbbbbbbbbbbbbbb333333ffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffff33333bbbbb333333333bbbbb33333fffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffff33333bb333333333333333333333333ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff333333333333333333333333377733333fffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffff33333333333333333333333337777733333ffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffff3333333333333333333333333377777733333fffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffff3333333333333333333333333377777733333fffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffff3333bbbbbbbbbbbbbbbbbbbbbbbb77777b33333ffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffff3333bbbbbbbbbbbbbbbbbbbbbbbbbbb77bbbb3333fffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffff333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333fffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffff333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb77bbb333fffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffff333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb77bbbb333ffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffff333bbb3333333333333333333333333333333b3b333ffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffff333b33333333333333333333333333333333b3b3333ffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffff33333333333333333333333333333333333333b3b3333fffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffff333333333333333333333333333333333333333b3b333fffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffff33333333333330333333333333333003333333b3b3333fffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffff333333333333330333333333333300003333333b3b333fffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffff333bbbbbbbbbbbb0bbbbbbbbbbbb0000bbbbbbbbbb333fffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffff333bbbbbbbbbbb0bbbbb0bbb0bbbb00bbbbbbbbbbb333fffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffff333bbbbbbbbbb0bbbbbbb0b0bbbbbbbbbbbbbbbbbb333fffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffff333bbbbbbbbbbbbbbbbbbb0bbbbbbbbbbbbbbbbbbb333fffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffff333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333fffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffff333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33ffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffff3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b333ffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffff333333333333333333333333333333333333b3b3b33ffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffff3333333333333333333333333333333333b3b3b33fffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffff333333333333333333333333333333333b3b3b333fffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffff33333333333333333333333333333333b3b3b3333fffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffff3333bbb33333333333333333333333b3b3b3333ffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffff333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333fffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffff3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333fffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffff3333bbbbbbbbbbbbbbbbbbbbbbbbbbb3333ffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff3333bbbbbbbbbbbbbbbbbbbbbbbbbb333fffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffff33333333333333333333333b3b3b333ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffff3333333333333333333b3b3b3b333fffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffff33333333333333333b3b3b33333ffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffff333333b3b3b3b3b3b333333ffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff33333333b3b3b33333333fffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffff333333333333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff333333333fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
eeeeeeeeeeeeeeeefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeffffffffffff
eeeeeeeeeeeeeeeeeeeeeefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffff
eeeeeeeeeeeeeeeeeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefffffffffffffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee99999999999999999999999999999999999999999eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee999999999999999999999999999999999999999999999999999999999999eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeee99999999999999999999999999999999999999999999999999999999999999999999999999eeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeee9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999eeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeee9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999eeeeeeeeeeeeee
eeeeeee99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999eeeeeeee
e999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999e
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999

__map__
002f2f2f2f2f2f2f2f2f0008040505060004050506004041000043440045006061006263000000464700004849000066670000004a4b000000656869000000008a8b8c8d8e8f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d3d2f2f2f2f2f2f2f3e0e081415151600141515160050510000535400550070710072730000005657000058590000767700007a6a6a6b0000686965690000009a9b9c9d9e9f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e081415151600141515160000000000000000000000000000000000000000000000000000000000007a5a5b6b000000787900000000aaabacadaeaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e08141515160014151516000000000000000000000000000000000000000000000000000000000000006a6a00000000650075000000babbbcbdbebf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e0824252526001415151600000000000000000000000000000000000000000000000000000000000000000000000000000000000000cacbcccdcecf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e0800000000002425252600000000000000000000000000000000000000000000000000000000000000000000000000000000000000dadbdcdddedf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2d2d000000000000002e2e080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0b0b0b0b0b0b0b0b0b0c180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010200000b1300e24010341103310e3210d3110b3100b600004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
010300001f410093211a4310a331154360c336114260c32314423093231e423213131152324313115232831310523105150f0110c011090110501100400004000040000400004000040000400004000040000400
0002000025450231402c4302c42015110121100010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000191501b1501c7511a751147510d7510070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000300000d43006441090510c0510f051131511c14125330210002100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002c4302a44127031220311d031140310602000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00000c6350000000000000000000000000000000000018635000000000000000000000000000000000000c6350000000000000000000000000000000000018635000000000018635246350c6350000024635
010e00000c63500600346000c600186000000000000006001863518600006000c600186000060000600000000c6350060000600006001860000000006000c6001863500600006001860000600006000000000000
010e000011040117301173011730117301173011735000000e0400e7300e7300e7300e7300e7300e7350000005040057300573005730057300573005735000000c0400c7300c7300c7300c7300c7300c73500000
010e00001813018120181201812518130181201812018125181301812018120181201812218122181221812516130161201612016120161201612216122161251613016120161201612516130161201612016125
010e00001113011120111201112511130111201112011125121301212012120121201212212122121221212511130111201112011120111201112211122111251113011120111201112511130111201112011125
010e00001813018130181201812018120181221811218115001000010000100001001213012120121201211517130171201712500100171301712017125001001613016120161250010016130161201612216125
010e00001113011130111201112011120111221111211115000000000000000000001813018120181201811511130111201112500000111301112011125000001013010120101250000010130101201012210125
6112000018000180002c0552d0502d045300553205032045300552d0502d0450010030050300450010032050320453004530000300003000000000001002d0553005030045320553005030045000003205032040
611200003205530050300452d0550000000000000000000000000000000000000000000000000000000000002b0502b0452d0552e0502e0402e0552e0402e0402e03530050300452e0502e045000000000000000
011200001104011730117301173500000110450c0400c7300c7300c035000000c04511040117301173011735000000c0451104011735110450c0400c7350c0451104011730117301173500000110450c0400c730
011200000c7300c735000000c0451104011730117301173500000110450c0400c7350c0451104011730117350c0400c7300c7300c735000000c0450704007730077300703500000070450c0400c7300c7300c035
01120000000000c0351304013735130450c0400c7300c7351104011730117301173011730117350c0400c7300c7300c7200c7350c04511040117301173011730117350c0451304013735130450c7400c0350c045
6112000000000000000000000000300503004500000300552d0502d0402d0452e0502e04530050300403074030730307250000030710307103071230712307150000029735327303273529735307303073500000
611200001c0221c0151c0301c0221c01500000000000000000000000000000000000000000000000000182351d2352123524235292352d1302d1202d1152b1302b1202b115291302912029115000000000000000
011200000c625000000000000000000000c6251863500000000000000000000000000c625000000000000000000000c6251863500000000000000000000000000c625000000000000000000000c6251863500000
01120000000000000000000000000c625000000000000000000000c6251863500000000000000000000000000c625000000000000000000000c62518635000000000000000000000c6000c625000000000000000
01120000000000c6251863500000000000000000000000000c625000000000000000000000c6251863500000000000000000000000000c625000000000000000000000c625186350000018615186251863500000
011200001d0301d0201d0101d0121d0121d0121d0121d0121d0151d0001d000000000000000000000001d0301d0221d0150000000000000001d0201d015150251d0201d015180251d0201d0151d0252901229015
00120000240352103021025000000000000000240151d0301d0201d0101d0121d015000001d0301d0221d0150000000000000000000000000000000000000000000001f0301f0251a0351c0301c0221c0251c030
011200001d0201d025180251d0201d0251d0252901229015240152102021020210250000000000000001d0201d0221d0150000000000000001d0201d0221d0150000000000000001d0301d0351d0350000000000
00120000000001d0201d0201d01500000000000e0001d0201d0201d01500000291352413521135181351512500000000000000000000000000000000000000000000016130161251f13500000000000000000000
0112000000000000001f1301f125000001c1301c125000001d0301d0201d0201d0201d0121d0121d0221d0221d0221d0251d000241201a1301a1221a12518130181221812521120211221f1221d1220000000000
6112000000000000000000000000300503004500000300552d0502d0402d0452e0502e04530050300403074030730307250000030700290302902229025290302902229025180201802518020180250000000000
0012000000000000002905029045000002605529050290452d0502d045000002605529050290452605529050290452d0502d0422d05526050260402605500000000000000000000290552b0552d0552b0502b045
00120000000000000000000290552d0502d0452e05530050300453205032740327423274232755000000000000000000002e0553005030045320503204032740327450000000000000002d0502d0452e05532050
00120000320553505534050340403404500000000002d0552b0502b0402b04530050300452d7502d7402d7402d7422d7422d735000001100011000110001100011000110002d1252e1252d1252d1252b12529125
011200000a0200a0250a0251a035000000a0250702007020070251d03500000070250c0200c0200c0251d0001d0000c0251302013020130251d0001d0000c0250a0200a0200a0250e0300e0250a0250702007020
00120000070250000000000070250c0200c0200c02500000000000c0250c0200c0200c0250c0200c0200c02513020130201302500000000000e0251302013025130250000013000130250c0200c0200c0200c020
011200000c0120c0150c0200c0200c0200c0120c015000001102011020110101101500000110250c0200c0200c0120c015000000c0251d0201d0121d0151d0121d0150c0251102011025110250c0200c0250c025
001200000000000000110001d23500000000000000000000130001f23500000000001f1301f1301f1321f1221f1221f1250000000000000001f1301f1201f1252113021120211252113021125000001d1301d120
001200001d1201d1201d115000000000000000182250000000000000000000000000000000000000000182351a1301a1251a13500000000001a2251a1301a1301a1301a135000000000000000000000000013120
0012000013125000001613016120161201612016115000001513015120151201512015122151121511500000000000000000000000001a1221a1221a125181221812218125000000000000000000000000000000
0012000011030110301102500000000001103000000000000000000000110350c0350503005025110350c0300c025000001113011120111201112211122111250000000000000000000000000000000000000000
011200000c6250030000000002150c6350c6351863500000000000c2150000000000246250000000000002250000018625246250000024615002000000000000000000c600000000000000000000000c60000000
011200002114021140211302113021130211302113221132211322112221115000002114021130211322112221125000001d0301d7201d7201d7221d7221d7250000000000000000000000000000000000000000
001200002904029040290202902029020290202902229022290222902229015000002904029030290322902229025000000000000000000000000000000000000000000000000000000000000000000000000000
001200001102011022151151811018115151150e0220e022131151611016115131150702207022131151611016115131150c0220c022151151811018115151151102015115181100000000000110250c0200c025
001200000c02518000180000c0250000000000000000702007020070251c1301c1201c1251c0301c0551102500000000000000000000000000000000000000000000000000000000000000000000000000000000
0112000000625000000c60026625000000c62500000000000c62526625000000c62500000000000c60026625000000c62500000000000c62526625000000c62500000000000000026625000000c6250000000000
000900000c6200c61524620246150c6000c6000c6200c6150e1300e1300e1200e1200e1200e12024620246150e1000e1000e1000e1000c6200c61500000000002462024625246202462524620246250c6200c615
00120000181301812018125181301812018125181301812018122181220c1250f1251613016120161201612216122161251613016120161251613016120161251813018120181221811218115000000000000000
00120000151152212022115000001d1301d1201d1251d1301d1250000019130191201912519130191250000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001200001d1301d1201d1251d1301d1201d1251e1301e1201e1221e1221e1221e1251d1301d1201d1201d1221d1221d1251d1301d1201d1251d1301d1201d1251d1301d1201d1221d1121d115000000000000000
001200001e0001d1201d1150000021130211202112521130211250000021130211202112521130211250000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 0a094b4c
01 2e2c3032
00 2f2d3133
01 1116190f
00 12171a10
00 13181514
00 11161b0f
00 12171c10
00 13181d1e
00 2216251f
00 23172620
02 24182721
04 28292a2b
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 0a090b0c
00 0a080d0e

