serial_count = 0
CHOSEN = 1
amounts = {8192/16, 8192/8, 8192/4, 8192/2, 8192/1}

function btn_helper(f, a, b)
   return f(a) and f(b) and 0 or f(a) and 0xffff or f(b) and 1 or 0
end

function xbtnp()return btn_helper(btnp,0,1)end

function _update60()
  CHOSEN = mid(CHOSEN+xbtnp(), 1, #amounts)
  serial(0x0804, 0x8000, amounts[CHOSEN])

  if not flashing and (btnp(4) or btnp(5)) do
    flashing = (flashing or -1)+1
  end

  if flashing then
    flashing += 1
    if flashing >= 16/CHOSEN then
      flashing = nil
    end
  end
end

function _draw()
  cls()
  print("\f6unix pipe speed test for \f8p\f9i\fbc\fco\fd-\fe8", 1, 1, 7)
  print("time: "..t(), 1, 10, 8)
  print("stdin bytes per frame: "..amounts[CHOSEN], 1, 20, 9)
  print("fps: "..stat'7',   1, 30, 11)
  print("cpu: "..stat'1',   1, 40, 12)
  print("left/right to change amount", 1, 50, 13)

  if flashing then
    cls(10)
  end
end
