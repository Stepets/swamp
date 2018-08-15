local util = {}

function util.deep_copy(obj, tab)
  tab = tab or ''
  if type(obj) == 'table' then
    local result = {}
    for k,v in pairs(obj) do
      result[k] = util.deep_copy(v, tab .. '\t')
    end
    return result
  else
    return obj
  end
end

function util.mergesort(a, b, cmp)
  local result = {}
  local pa, pb = 1, 1
  while pa <= #a and pb <= #b do
    if cmp(a[pa], b[pb]) then
      result[#result + 1] = a[pa]
      pa = pa + 1
    else
      result[#result + 1] = b[pb]
      pb = pb + 1
    end
  end

  for i = pa, #a do
    result[#result + 1] = a[i]
  end

  for i = pb, #b do
    result[#result + 1] = b[i]
  end

  return result
end

function util.binsearch(tbl, cmp, l, r)
  l = l or 0
  r = r or #tbl

  if r - 1 <= l then return l end

  local mid = math.floor((l + r) / 2)
  if cmp(tbl[mid]) then
    l = mid
  else
    r = mid
  end
  return binsearch(tbl, cmp, l, r)
end

return util
