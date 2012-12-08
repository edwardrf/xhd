function regression(h)
    n = table.getn(h)
    sumxy = 0
    sumx  = 0
    sumy  = 0
    sumx2 = 0
    sumy2 = 0
    for x, y in ipairs(h) do
        sumxy = sumxy + x * y
        sumx  = sumx + x
        sumy  = sumy + y
        sumx2 = sumx2 + x * x
        sumy2 = sumy2 + y * y
--        print("x, ", x, "  y, ", y)
    end
    b = (sumxy * n - sumx * sumy) / (sumx2 * n - sumx * sumx)

    sx = (sumx2 - sumx * sumx / n) / n
    sy = (sumy2 - sumy * sumy / n) / n

    r = (n * sumxy - sumx * sumy) /(((n * sumx2 - sumx * sumx) * (n * sumy2 - sumy * sumy)) ^ 0.5)

    return b, r
end

