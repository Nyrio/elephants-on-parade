#!/usr/bin/env python3
import xml.etree.ElementTree as ET

FILES_IN = ["dance_0.svg", "dance_1.svg", "dance_2.svg", "dance_3.svg"]
XMIN, XMAX = -16/9, 16/9
YMIN, YMAX = 1, -1

int_arr = []
for idx in range(4):
    filename = FILES_IN[idx]
    # Clear namespaces
    it = ET.iterparse(filename)
    for _, el in it:
        if '}' in el.tag:
            el.tag = el.tag.split('}', 1)[1]  # strip all namespaces
    root = it.root

    vxmin, vymin, vxmax, vymax = tuple(map(float, root.attrib["viewBox"].split()))
    def view_func(x, y):
        return (
            (x - vxmin) * (XMAX - XMIN) / (vxmax - vxmin) + XMIN,
            (y - vymin) * (YMAX - YMIN) / (vymax - vymin) + YMIN
        )

    svg_paths = root.findall("path")
    total_arr = []
    for svg_path in svg_paths:
        transform = svg_path.attrib["transform"]
        def translate(tx, ty):
            def ret_func(x, y):
                return x + tx, y + ty
            return ret_func
        if transform.startswith("matrix"):
            a, b, c, d, e, f = map(float,
                                   transform[transform.index("(") + 1
                                             :transform.index(")")].split(" "))
            def matrix_transform(a, b, c, d, e, f):
                def ret_func(x, y):
                    return (a * x + c * y + e, b * x + d * y + f)
                return ret_func
            tr_func = matrix_transform(a, b, c, d, e, f)
        else:
            tr_func = eval(transform)

        path_str = svg_path.attrib["d"]
        for ctrl_letter in ["M", "L", "C", "Z"]:
            path_str = path_str.replace(ctrl_letter, " %s " % ctrl_letter)
        path = list(filter(lambda x: x, path_str.split()))

        cx, cy = 0, 0
        arr = []
        i = 0
        while i < len(path):
            if path[i] == "M":
                nx, ny = map(float, path[i+1:i+3])
                i += 3
            elif path[i] == "L":
                nx, ny = map(float, path[i+1:i+3])
                x1, y1 = (2 * cx + nx) / 3, (2 * cy + ny) / 3
                x2, y2 = (cx + 2 * nx) / 3, (cy + 2 * ny) / 3
                arr += [cx, cy, x1, y1, x2, y2, nx, ny]
                i += 3
            elif path[i] == "C":
                x1, y1, x2, y2, nx, ny = map(float, path[i+1:i+7])
                arr += [cx, cy, x1, y1, x2, y2, nx, ny]
                i += 7
            else:
                break
            cx, cy = nx, ny

        # Apply transformation
        for offset in range(0, len(arr), 2):
            arr[offset], arr[offset + 1] = view_func(*tr_func(arr[offset],
                                                              arr[offset + 1]))
        total_arr += arr

    for i in range(0, len(total_arr), 2):
        int_arr.append(int(total_arr[i] * 70) + 128
                       + 256 * (int(total_arr[i + 1] * 70) + 128)
                       + 65536 * (int(total_arr[i + 2] * 70) + 128)
                       + 16777216 * (int(total_arr[i + 3] * 70) + 128))

# Output array on stdout
print(
    ("const uint data[{size}] = uint[{size}] (\n{vec_data}\n);"
    ).format(vec_data=("\n".join("".join(("%du," * len(int_arr[offset:offset + 10]))
                                         % tuple(int_arr[offset:offset + 10]))
                                 for offset in range(0, len(int_arr), 10))
                       )[:-1],
             size=len(int_arr))
)
