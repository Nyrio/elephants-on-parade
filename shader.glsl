#define AA 1
#define SPLINE 8

// Adapted from https://stackoverflow.com/a/218081/8259873
int intersects(vec2 A, vec2 B, vec2 C, vec2 D)
{
    const vec2 m1 = vec2(1,-1);
    float c = dot(B, A.yx * m1);
    vec2 bt = (B - A).yx * m1;
    if ((dot(C, bt) + c) * (dot(D, bt) + c) > 0.0) return 0;

    c = dot(D, C.yx * m1);
    bt = (D - C).yx * m1;
    return ((dot(A, bt) + c) * (dot(B, bt) + c) > 0.0) ? 0 : 1;
}

float minv(vec4 v)
{
    return min(min(v.x,v.y),min(v.z,v.w));
}
float maxv(vec4 v)
{
    return max(max(v.x,v.y),max(v.z,v.w));
}

vec2 valBezier(vec4 Xs, vec4 Ys, float t)
{
    float s = 1.0 - t;
    vec4 vt = vec4(s*s*s, 3.0*s*s*t, 3.0*s*t*t, t*t*t);
    return vec2(dot(Xs, vt), dot(Ys, vt));
}

int nbBezierInter(vec2 uv, vec2[4] pts)
{
    const vec2 ref = vec2(0, 1.1);
    vec4 Xs = vec4(pts[0].x, pts[1].x, pts[2].x, pts[3].x);
    vec4 Ys = vec4(pts[0].y, pts[1].y, pts[2].y, pts[3].y);
    if(uv.x < minv(Xs) || uv.x > maxv(Xs)
       || uv.y < minv(Ys) || uv.y > maxv(Ys))
        return intersects(uv, ref, pts[0], pts[3]);
    const int slices = SPLINE;
    int res = 0;
    vec2 a = pts[0];
    float ot = 0.0;
    for(int i = 1; i < slices; i++)
    {
        float t = float(i)/float(slices-1);
        vec2 b = valBezier(Xs, Ys, t);
        res += intersects(uv, ref, a, b);
        a = b;
    }

    return res;
}

float barry_goldman(vec4 X, vec4 T, float t)
{
    vec3 A = ((T.yzw - t) * X.xyz + (t - T.xyz) * X.yzw) / (T.yzw - T.xyz);
    vec2 B = ((T.zw - t) * A.xy + (t - T.xy) * A.yz) / (T.zw - T.xy);
	return ((T.z - t) * B.x + (t - T.y) * B.y) / (T.z - T.y);
}
int nbBezierInter_catmullRom(vec2 uv, vec4[8] pts, vec4 times, float t)
{
    vec2[4] inter;
    for(int l = 0; l < 2; l++) {
        inter[2*l] = vec2(barry_goldman(vec4(pts[l].x, pts[l+2].x,
                                           pts[l+4].x, pts[l+6].x),
                                      times, t),
                        barry_goldman(vec4(pts[l].y, pts[l+2].y,
                                           pts[l+4].y, pts[l+6].y),
                                      times, t));
        inter[2*l+1] = vec2(barry_goldman(vec4(pts[l].z, pts[l+2].z,
                                           pts[l+4].z, pts[l+6].z),
                                      times, t),
                        barry_goldman(vec4(pts[l].w, pts[l+2].w,
                                           pts[l+4].w, pts[l+6].w),
                                      times, t));
    }
    return nbBezierInter(uv, inter);
}

vec4 int_to_vec4(uint val) {
    return vec4((float(val & 255u) - 128.0) / 70.0,
                (float((val >> 8u) & 255u) - 128.0) / 70.0,
                (float((val >> 16u) & 255u) - 128.0) / 70.0,
                (float((val >> 24u) & 255u) - 128.0) / 70.0);
}

vec2 jump(vec2 pos1, vec2 pos2, float t1, float t2, float t)
{
    if(t <= t1) return pos1;
    if(t >= t2) return pos2;
    float ti = smoothstep(t1, t2, t);
    return vec2(pos1.x*(1.0-ti) + pos2.x*ti,
                pos1.y*(1.0-ti) + pos2.y*ti + 0.4*ti*(1.0-ti)*abs(pos2.x-pos1.x));
}

vec3 shot1(vec2 pixCoord, float time)
{
    const int nbCurves = 27;
const uint data[216] = uint[216] (
2690162012u,2841486681u,2874714461u,2924981334u,2973871703u,3143940700u,3144399716u,3094657395u,3212884084u,3097083283u,
3097344153u,3114776992u,3098589607u,2947722947u,2881007538u,2846862001u,2796595631u,2645401777u,2581044653u,2178977244u,
2112782816u,1926788067u,1992192728u,2327218121u,2092927670u,1722380470u,1537828521u,1335252901u,1335775126u,1218333352u,
1201162398u,1316243318u,1366511220u,1484937090u,1552046210u,1650745971u,1566859876u,1432180576u,1381455197u,1431065677u,
1497847116u,1665621317u,1749050183u,1832741437u,1950313789u,2018211403u,2051766347u,2337178439u,2201717582u,1966044481u,
2014803247u,2200404259u,2552595239u,2640092476u,2756681554u,2840896849u,2857281876u,2924325965u,2957028941u,3075781451u,
3109664596u,3093674593u,3228809317u,3113401990u,3113662866u,3098065571u,3048257704u,2930290360u,2863509160u,2846075559u,
2795874723u,2661393062u,2613681825u,2178256862u,2078573013u,1925935831u,1957655243u,2327152585u,2075495093u,1688759987u,
1504208040u,1335317918u,1302548375u,1218136486u,1200900251u,1316243064u,1383419508u,1535137669u,1585142656u,1634754422u,
1534026096u,1315853436u,1265061486u,1330137936u,1363365704u,1498764620u,1582192981u,1682792780u,1783587917u,1851026514u,
1934323284u,2336587845u,2201783109u,1948873787u,2014802985u,2200142363u,2569306915u,2672991026u,2705366596u,2856691264u,
2873076293u,2940054844u,3023155005u,3091838021u,3142367305u,3092887895u,3211114585u,3112222330u,3112483200u,3096754574u,
3063724180u,2929438379u,2862657179u,2845158040u,2794957205u,2660541080u,2596511380u,2227934409u,2161804491u,1992718036u,
1991014086u,2376437176u,2242481573u,2041020587u,1958377895u,1705667514u,1622107562u,1419859116u,1419531425u,1502762390u,
1552898450u,1687052687u,1635804302u,1517248631u,1433950831u,1266109569u,1214925687u,1263618388u,1313688401u,1364939093u,
1431261531u,1531663950u,1632131915u,1749771593u,1833134155u,2319155764u,2233698875u,1914401339u,1963618843u,2199290126u,
2501477142u,2655296293u,2689375568u,2890770504u,2907089997u,2974068292u,2973348164u,3125524038u,3159341643u,3143547997u,
3261774686u,3163079295u,3180117128u,3147546004u,3131292571u,2980032684u,2913251743u,2895818141u,2829036698u,2660541086u,
2579275412u,2194904024u,2095022803u,1942581971u,1940747209u,2376436667u,2242547109u,1772450737u,1655663013u,1403016877u,
1319457696u,1251363486u,1267747478u,1350847880u,1400983684u,1602836869u,1568694153u,1517313664u,1433950832u,1266110081u,
1231965047u,1263618144u,1313753937u,1364938836u,1397772635u,1565088074u,1632066889u,1749771593u,1833134155u,2319221557u,
2184022588u,1864789575u,1863937830u,2115861015u,2400747037u,2639304749u
);

    vec2 uv = (2.0*pixCoord - iResolution.xy) / iResolution.y;
    vec2 uv_base = vec2(5,2.2) * uv;

    vec2[5] positions = vec2[5] (
        uv_base * mix(vec2(1.0,1.0), vec2(0.75,0.75), smoothstep(6.5,20.0,time))
        	- jump(vec2(0,0.6), vec2(0.0,-0.75), 6.5, 20.0, time),
        uv_base * mix(vec2(1.0,1.0), vec2(0.8,0.8), smoothstep(5.5,6.0,time))
        	- jump(vec2(0,0.6), vec2(4.5,-0.8), 5.5, 6.0, time),
        uv_base * mix(vec2(1.0,1.0), vec2(0.8,0.8), smoothstep(4.5,5.0,time))
        	- jump(vec2(0,0.6), vec2(-4.5,-0.8), 4.5, 5.0, time),
        uv_base * mix(vec2(1.0,1.0), vec2(1.1,1.1), smoothstep(3.0,3.5,time))
        	- jump(vec2(0,0.6), vec2(4.6,1.0), 3.0, 3.5, time),
        uv_base * mix(vec2(1.0,1.0), vec2(1.1,1.1), smoothstep(2.0,2.5,time))
        	- jump(vec2(0,0.6), vec2(-4.6,1.0), 2.0, 2.5, time)
    );

    int[5] nbInter = int[5] (0,0,0,0,0);
    float[5] startingTimes = float[5] (5.5,4.5,3.0,2.0,0.0);

    float animTime = 3.0*time;
    int k;
    k = int(animTime);
    for(int i = 0; i < nbCurves; i++) {
        vec4[8] pts;

        for(int l = 0; l < 2; l++) {
          pts[l] = int_to_vec4(data[2*nbCurves*(k % 4)+2*i+l]);
          pts[2+l] = int_to_vec4(data[2*nbCurves*((k + 1) % 4)+2*i+l]);
          pts[4+l] = int_to_vec4(data[2*nbCurves*((k + 2) % 4)+2*i+l]);
          pts[6+l] = int_to_vec4(data[2*nbCurves*((k + 3) % 4)+2*i+l]);
        }
        vec4 times = vec4(-1, 0, 1, 2);

        for(int j = 0; j < 5; j++) {
            if(time >= startingTimes[j]) {
        		nbInter[j] += nbBezierInter_catmullRom(positions[j], pts, times, fract(animTime));
            }
        }
    }

    vec3 col = vec3(0.15,0,0.15);

    uv = uv + 0.05 * time * vec2(1,0.4);
    if((nbInter[0] & 1) == 1) {
        col = vec3(0.55,0.1,0.55);
    }
    if((nbInter[1] & 1) == 1) {
        col = vec3(0.4,0.05,0.3);
        float dd = mod(uv.y, 0.1);
        col = mix(col, vec3(0.7,0.15,0.2), 1.0 - smoothstep(0.03, 0.045, dd) + smoothstep(0.085, 0.1, dd));
    }
    if((nbInter[2] & 1) == 1) {
        col = vec3(0.05,0.6,0.6);
        float dd = mod(uv.x, 0.1);
        col = mix(col, vec3(0.3,0.9,0.5), 1.0 - smoothstep(0.03, 0.045, dd) + smoothstep(0.085, 0.1, dd));
    }
    if((nbInter[3] & 1) == 1 && (nbInter[1] & 1) == 0) {
        col = vec3(0.1,0.25,0.9);
        float dd = mod(uv.y - uv.x, 0.15);
        col = mix(col, vec3(0.05,0.8,0.9), 1.0 - smoothstep(0.05, 0.07, dd) + smoothstep(0.13, 0.15, dd));
    }
    if((nbInter[4] & 1) == 1 && (nbInter[2] & 1) == 0) {
        col = vec3(0.4,0.0,0.4);
        vec2 uv_o = uv + vec2(0, 0.042 * round(12.0*uv.x));
        vec2 uv_grid = vec2(round(12.0*uv_o.x), round(12.0*uv_o.y));
        col = mix(vec3(0.8,0.77,0.2), col, smoothstep(0.35, 0.45, distance(12.0*uv_o, uv_grid)));
    }

    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float AAf = float(AA);
    vec3 avgcol = vec3(0);
    for(int i = 0; i < AA; i++) {
        for(int j = 0; j < AA; j++) {
            vec2 coord = fragCoord + vec2(i, j) / AAf;
            avgcol += shot1(coord, iTime);
        }
    }
   	fragColor = vec4(avgcol / (AAf * AAf), 1.0);
}
