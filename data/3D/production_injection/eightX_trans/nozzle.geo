SetFactory("OpenCASCADE");
//Geometry.CopyMeshingMethod = 1;

If(Exists(size))
    basesize=size;
Else
    basesize=0.0064;
EndIf

If(Exists(blratio))
    boundratio=blratio;
Else
    boundratio=4.0;
EndIf

If(Exists(blratiocavity))
    boundratiocavity=blratiocavity;
Else
    boundratiocavity=2.0;
EndIf

If(Exists(blratioinjector))
    boundratioinjector=blratioinjector;
Else
    boundratioinjector=2.0;
EndIf

If(Exists(injectorfac))
    injector_factor=injectorfac;
Else
    injector_factor=4.0;
EndIf

If(Exists(shearfac))
    shear_factor=shearfac;
Else
    shear_factor=4.0;
EndIf

If(Exists(isofac))
    iso_factor=isofac;
Else
    iso_factor=2.0;
EndIf

If(Exists(cavityfac))
    cavity_factor=cavityfac;
Else
    cavity_factor=4.0;
EndIf

bigsize = basesize*4;     // the biggest mesh size 
inletsize = basesize*2;   // background mesh size upstream of the nozzle
isosize = basesize/iso_factor;       // background mesh size in the isolator
nozzlesize = basesize/12;       // background mesh size in the nozzle
cavitysize = basesize/cavity_factor; // background mesh size in the cavity region
shearsize = isosize/shear_factor;

inj_h=4.e-3;  // height of injector (bottom) from floor
inj_t=1.59e-3; // diameter of injector
inj_d = 20e-3; // length of injector
injectorsize = inj_t/injector_factor; // background mesh size in the cavity region

Printf("basesize = %f", basesize);
Printf("inletsize = %f", inletsize);
Printf("isosize = %f", isosize);
Printf("nozzlesize = %f", nozzlesize);
Printf("cavitysize = %f", cavitysize);
Printf("shearsize = %f", shearsize);
Printf("injectorsize = %f", injectorsize);
Printf("boundratio = %f", boundratio);
Printf("boundratiocavity = %f", boundratiocavity);
Printf("boundratioinjector = %f", boundratioinjector);

p = 1;
l = 1;
s = 1;

//Top Wall
p_nozzle_top_start = p;
Point(p++) = {0.21,0.0270645,0.0,basesize};
Point(p++) = {0.2280392417062,0.0270645,0.0,basesize};
Point(p++) = {0.2287784834123,0.0270645,0.0,basesize};
Point(p++) = {0.2295177251185,0.0270645,0.0,basesize};
Point(p++) = {0.2302569668246,0.0270645,0.0,basesize};
Point(p++) = {0.2309962085308,0.0270645,0.0,basesize};
Point(p++) = {0.231735450237,0.0270645,0.0,basesize};
Point(p++) = {0.2324746919431,0.0270645,0.0,basesize};
Point(p++) = {0.2332139336493,0.0270645,0.0,basesize};
Point(p++) = {0.2339531753555,0.0270645,0.0,basesize};
Point(p++) = {0.2346924170616,0.02679523462424,0.0,basesize};
Point(p++) = {0.2354316587678,0.02628798808666,0.0,basesize};
Point(p++) = {0.2361709004739,0.02578074154909,0.0,basesize};
Point(p++) = {0.2369101421801,0.02527349501151,0.0,basesize};
Point(p++) = {0.2376493838863,0.02476624847393,0.0,basesize};
Point(p++) = {0.2383886255924,0.02425900193636,0.0,basesize};
Point(p++) = {0.2391278672986,0.02375175539878,0.0,basesize};
Point(p++) = {0.2398671090047,0.02324450886121,0.0,basesize};
Point(p++) = {0.2406063507109,0.02273726232363,0.0,basesize};
Point(p++) = {0.2413455924171,0.02223001578605,0.0,basesize};
Point(p++) = {0.2420848341232,0.02172276924848,0.0,basesize};
Point(p++) = {0.2428240758294,0.0212155227109,0.0,basesize};
Point(p++) = {0.2435633175355,0.02070827617332,0.0,basesize};
Point(p++) = {0.2443025592417,0.02020102963575,0.0,basesize};
Point(p++) = {0.2450418009479,0.01969378309817,0.0,basesize};
Point(p++) = {0.245781042654,0.0191865365606,0.0,basesize};
Point(p++) = {0.2465202843602,0.01867929002302,0.0,basesize};
Point(p++) = {0.2472595260664,0.01817204348544,0.0,basesize};
Point(p++) = {0.2479987677725,0.01766479694787,0.0,basesize};
Point(p++) = {0.2487380094787,0.01715755041029,0.0,basesize};
Point(p++) = {0.2494772511848,0.01665030387271,0.0,basesize};
Point(p++) = {0.250216492891,0.01614305733514,0.0,basesize};
Point(p++) = {0.2509557345972,0.01563581079756,0.0,basesize};
Point(p++) = {0.2516949763033,0.01512856425999,0.0,basesize};
Point(p++) = {0.2524342180095,0.01462131772241,0.0,basesize};
Point(p++) = {0.2531734597156,0.01411407118483,0.0,basesize};
Point(p++) = {0.2539127014218,0.01360682464726,0.0,basesize};
Point(p++) = {0.254651943128,0.01309957810968,0.0,basesize};
Point(p++) = {0.2553911848341,0.01259233157211,0.0,basesize};
Point(p++) = {0.2561304265403,0.01208508503453,0.0,basesize};
Point(p++) = {0.2568696682464,0.01157783849695,0.0,basesize};
Point(p++) = {0.2576089099526,0.01107059195938,0.0,basesize};
Point(p++) = {0.2583481516588,0.0105633454218,0.0,basesize};
Point(p++) = {0.2590873933649,0.01005609888422,0.0,basesize};
Point(p++) = {0.2598266350711,0.009548852346649,0.0,basesize};
Point(p++) = {0.2605658767773,0.009041605809072,0.0,basesize};
Point(p++) = {0.2613051184834,0.008534359271496,0.0,basesize};
Point(p++) = {0.2620443601896,0.00802711273392,0.0,basesize};
Point(p++) = {0.2627836018957,0.007519866196344,0.0,basesize};
Point(p++) = {0.2635228436019,0.007012619658768,0.0,basesize};
Point(p++) = {0.2642620853081,0.006505373121192,0.0,basesize};
Point(p++) = {0.2650013270142,0.005998126583615,0.0,basesize};
Point(p++) = {0.2657405687204,0.005490880046039,0.0,basesize};
Point(p++) = {0.2664798104265,0.004983633508463,0.0,basesize};
Point(p++) = {0.2672190521327,0.004476386970887,0.0,basesize};
Point(p++) = {0.2679582938389,0.003969140433311,0.0,basesize};
Point(p++) = {0.268697535545,0.003461893895735,0.0,basesize};
Point(p++) = {0.2694367772512,0.002954647358158,0.0,basesize};
Point(p++) = {0.2701760189573,0.002447400820582,0.0,basesize};
Point(p++) = {0.2709152606635,0.001940154283006,0.0,basesize};
Point(p++) = {0.2716545023697,0.00143290774543,0.0,basesize};
Point(p++) = {0.2723937440758,0.0009256612078538,0.0,basesize};
Point(p++) = {0.273132985782,0.0004184146702776,0.0,basesize};
Point(p++) = {0.2738722274882,-8.883186729857e-05,0.0,basesize};
Point(p++) = {0.2746114691943,-0.0005960784048747,0.0,basesize};
Point(p++) = {0.2753507109005,-0.001103324942451,0.0,basesize};
Point(p++) = {0.2760899526066,-0.001610571480027,0.0,basesize};
Point(p++) = {0.2768291943128,-0.0021178180176,0.0,basesize};
Point(p++) = {0.277568436019,-0.002625063418531,0.0,basesize};
Point(p++) = {0.2783076777251,-0.003128071371827,0.0,basesize};
Point(p++) = {0.2790469194313,-0.00356543025825,0.0,basesize};
Point(p++) = {0.2797861611374,-0.003924485596916,0.0,basesize};
Point(p++) = {0.2805254028436,-0.004209800511799,0.0,basesize};
Point(p++) = {0.2812646445498,-0.004425962626834,0.0,basesize};
Point(p++) = {0.2820038862559,-0.004577559566121,0.0,basesize};
Point(p++) = {0.2827431279621,-0.004669178953759,0.0,basesize};
Point(p++) = {0.2834823696682,-0.004705408413847,0.0,basesize};
Point(p++) = {0.2842216113744,-0.004697204954745,0.0,basesize};
Point(p++) = {0.2849608530806,-0.00465704436755,0.0,basesize};
Point(p++) = {0.2857000947867,-0.004586244418798,0.0,basesize};
Point(p++) = {0.2864393364929,-0.004485025473862,0.0,basesize};
Point(p++) = {0.2871785781991,-0.004353607898117,0.0,basesize};
Point(p++) = {0.2879178199052,-0.004192212056935,0.0,basesize};
Point(p++) = {0.2886570616114,-0.00400105831569,0.0,basesize};
Point(p++) = {0.2893963033175,-0.003780367039754,0.0,basesize};
Point(p++) = {0.2901355450237,-0.003530358594502,0.0,basesize};
Point(p++) = {0.2908747867299,-0.003251253345306,0.0,basesize};
Point(p++) = {0.291614028436,-0.002943271657539,0.0,basesize};
Point(p++) = {0.2923532701422,-0.002613060084159,0.0,basesize};
Point(p++) = {0.2930925118483,-0.00228623916318,0.0,basesize};
Point(p++) = {0.2938317535545,-0.001965379671836,0.0,basesize};
Point(p++) = {0.2945709952607,-0.001650408524638,0.0,basesize};
Point(p++) = {0.2953102369668,-0.001341252636095,0.0,basesize};
Point(p++) = {0.296049478673,-0.001037838920719,0.0,basesize};
Point(p++) = {0.2967887203791,-0.0007400942930211,0.0,basesize};
Point(p++) = {0.2975279620853,-0.0004479456675107,0.0,basesize};
Point(p++) = {0.2982672037915,-0.0001613199586989,0.0,basesize};
Point(p++) = {0.2990064454976,0.0001198559189035,0.0,basesize};
Point(p++) = {0.2997456872038,0.0003956550507858,0.0,basesize};
Point(p++) = {0.30048492891,0.0006661505224375,0.0,basesize};
Point(p++) = {0.3012241706161,0.0009314154193479,0.0,basesize};
Point(p++) = {0.3019634123223,0.001191522827006,0.0,basesize};
Point(p++) = {0.3027026540284,0.001446545830902,0.0,basesize};
Point(p++) = {0.3034418957346,0.001696557516524,0.0,basesize};
Point(p++) = {0.3041811374408,0.001941630969363,0.0,basesize};
Point(p++) = {0.3049203791469,0.002181839274906,0.0,basesize};
Point(p++) = {0.3056596208531,0.002417255518644,0.0,basesize};
Point(p++) = {0.3063988625592,0.002647952786067,0.0,basesize};
Point(p++) = {0.3071381042654,0.002874004162662,0.0,basesize};
Point(p++) = {0.3078773459716,0.003095482733921,0.0,basesize};
Point(p++) = {0.3086165876777,0.003312461585331,0.0,basesize};
Point(p++) = {0.3093558293839,0.003525013802383,0.0,basesize};
Point(p++) = {0.31009507109,0.003733212470565,0.0,basesize};
Point(p++) = {0.3108343127962,0.003937130675367,0.0,basesize};
Point(p++) = {0.3115735545024,0.004136841502279,0.0,basesize};
Point(p++) = {0.3123127962085,0.004332418036789,0.0,basesize};
Point(p++) = {0.3130520379147,0.004523933364387,0.0,basesize};
Point(p++) = {0.3137912796209,0.004711460570563,0.0,basesize};
Point(p++) = {0.314530521327,0.004895072740805,0.0,basesize};
Point(p++) = {0.3152697630332,0.005074842960603,0.0,basesize};
Point(p++) = {0.3160090047393,0.005250844315447,0.0,basesize};
Point(p++) = {0.3167482464455,0.005423149890825,0.0,basesize};
Point(p++) = {0.3174874881517,0.005591832772228,0.0,basesize};
Point(p++) = {0.3182267298578,0.005756966045143,0.0,basesize};
Point(p++) = {0.318965971564,0.005918622795062,0.0,basesize};
Point(p++) = {0.3197052132701,0.006076876107472,0.0,basesize};
Point(p++) = {0.3204444549763,0.006231799067864,0.0,basesize};
Point(p++) = {0.3211836966825,0.006383464761726,0.0,basesize};
Point(p++) = {0.3219229383886,0.006531946274548,0.0,basesize};
Point(p++) = {0.3226621800948,0.00667731669182,0.0,basesize};
Point(p++) = {0.3234014218009,0.00681964909903,0.0,basesize};
Point(p++) = {0.3241406635071,0.006959016581669,0.0,basesize};
Point(p++) = {0.3248799052133,0.007095492225225,0.0,basesize};
Point(p++) = {0.3256191469194,0.007229149115187,0.0,basesize};
Point(p++) = {0.3263583886256,0.007360060337045,0.0,basesize};
Point(p++) = {0.3270976303318,0.007488298976289,0.0,basesize};
Point(p++) = {0.3278368720379,0.007613938118408,0.0,basesize};
Point(p++) = {0.3285761137441,0.00773705084889,0.0,basesize};
Point(p++) = {0.3293153554502,0.007857710253226,0.0,basesize};
Point(p++) = {0.3300545971564,0.007975989416904,0.0,basesize};
Point(p++) = {0.3307938388626,0.008091961425415,0.0,basesize};
Point(p++) = {0.3315330805687,0.008205699364247,0.0,basesize};
Point(p++) = {0.3322723222749,0.008317276318889,0.0,basesize};
Point(p++) = {0.333011563981,0.008426765374832,0.0,basesize};
Point(p++) = {0.3337508056872,0.008534231284918,0.0,basesize};
Point(p++) = {0.3344900473934,0.008639591517526,0.0,basesize};
Point(p++) = {0.3352292890995,0.008742817528548,0.0,basesize};
Point(p++) = {0.3359685308057,0.008843926036179,0.0,basesize};
Point(p++) = {0.3367077725118,0.008942933758618,0.0,basesize};
Point(p++) = {0.337447014218,0.009039857414062,0.0,basesize};
Point(p++) = {0.3381862559242,0.00913471372071,0.0,basesize};
Point(p++) = {0.3389254976303,0.009227519396758,0.0,basesize};
Point(p++) = {0.3396647393365,0.009318291160404,0.0,basesize};
Point(p++) = {0.3404039810427,0.009407045729847,0.0,basesize};
Point(p++) = {0.3411432227488,0.009493799823283,0.0,basesize};
Point(p++) = {0.341882464455,0.00957857015891,0.0,basesize};
Point(p++) = {0.3426217061611,0.009661373454925,0.0,basesize};
Point(p++) = {0.3433609478673,0.009742226429528,0.0,basesize};
Point(p++) = {0.3441001895735,0.009821145800914,0.0,basesize};
Point(p++) = {0.3448394312796,0.009898148287282,0.0,basesize};
Point(p++) = {0.3455786729858,0.00997325060683,0.0,basesize};
Point(p++) = {0.3463179146919,0.01004646947775,0.0,basesize};
Point(p++) = {0.3470571563981,0.01011782161825,0.0,basesize};
Point(p++) = {0.3477963981043,0.01018732374652,0.0,basesize};
Point(p++) = {0.3485356398104,0.01025499258077,0.0,basesize};
Point(p++) = {0.3492748815166,0.01032084483917,0.0,basesize};
Point(p++) = {0.3500141232227,0.01038489723995,0.0,basesize};
Point(p++) = {0.3507533649289,0.01044716650128,0.0,basesize};
Point(p++) = {0.3514926066351,0.01050766934138,0.0,basesize};
Point(p++) = {0.3522318483412,0.01056642247844,0.0,basesize};
Point(p++) = {0.3529710900474,0.01062344263065,0.0,basesize};
Point(p++) = {0.3537103317536,0.01067874651621,0.0,basesize};
Point(p++) = {0.3544495734597,0.01073235085333,0.0,basesize};
Point(p++) = {0.3551888151659,0.01078427236019,0.0,basesize};
Point(p++) = {0.355928056872,0.010834527755,0.0,basesize};
Point(p++) = {0.3566672985782,0.01088313375595,0.0,basesize};
Point(p++) = {0.3574065402844,0.01093010708125,0.0,basesize};
Point(p++) = {0.3581457819905,0.01097546444908,0.0,basesize};
Point(p++) = {0.3588850236967,0.01101922257765,0.0,basesize};
Point(p++) = {0.3596242654028,0.01106139818516,0.0,basesize};
Point(p++) = {0.360363507109,0.0111020079898,0.0,basesize};
Point(p++) = {0.3611027488152,0.01114106870976,0.0,basesize};
Point(p++) = {0.3618419905213,0.01117859706326,0.0,basesize};
Point(p++) = {0.3625812322275,0.01121460976848,0.0,basesize};
Point(p++) = {0.3633204739336,0.01124912354362,0.0,basesize};
Point(p++) = {0.3640597156398,0.01128215510688,0.0,basesize};
Point(p++) = {0.364798957346,0.01131372117646,0.0,basesize};
Point(p++) = {0.3655381990521,0.01134383847056,0.0,basesize};
Point(p++) = {0.3662774407583,0.01137252370737,0.0,basesize};
Point(p++) = {0.3670166824645,0.01139979360508,0.0,basesize};
Point(p++) = {0.3677559241706,0.01142566488191,0.0,basesize};
Point(p++) = {0.3684951658768,0.01145015425605,0.0,basesize};
Point(p++) = {0.3692344075829,0.01147327844568,0.0,basesize};
Point(p++) = {0.3699736492891,0.01149505416902,0.0,basesize};
Point(p++) = {0.3707128909953,0.01151549814426,0.0,basesize};
Point(p++) = {0.3714521327014,0.01153462708959,0.0,basesize};
Point(p++) = {0.3721913744076,0.01155245772322,0.0,basesize};
Point(p++) = {0.3729306161137,0.01156900676334,0.0,basesize};
Point(p++) = {0.3736698578199,0.01158429092815,0.0,basesize};
Point(p++) = {0.3744090995261,0.01159832693585,0.0,basesize};
Point(p++) = {0.3751483412322,0.01161113150463,0.0,basesize};
Point(p++) = {0.3758875829384,0.01162272135269,0.0,basesize};
Point(p++) = {0.3766268246445,0.01163311319823,0.0,basesize};
Point(p++) = {0.3773660663507,0.01164232375945,0.0,basesize};
Point(p++) = {0.3781053080569,0.01165036975455,0.0,basesize};
Point(p++) = {0.378844549763,0.01165726790172,0.0,basesize};
Point(p++) = {0.3795837914692,0.01166303491916,0.0,basesize};
Point(p++) = {0.3803230331754,0.01166768752507,0.0,basesize};
Point(p++) = {0.3810622748815,0.01167124243764,0.0,basesize};
Point(p++) = {0.3818015165877,0.01167371637508,0.0,basesize};
Point(p++) = {0.3825407582938,0.01167512605558,0.0,basesize};
Point(p++) = {0.38328,0.01167548819733,0.0,basesize};
p_nozzle_top_end = p-1;

//Bottom Wall
p_nozzle_bottom_start = p;
Point(p++) = {0.21,-0.0270645,0.0,basesize};
Point(p++) = {0.2280392417062,-0.0270645,0.0,basesize};
Point(p++) = {0.2287784834123,-0.0270645,0.0,basesize};
Point(p++) = {0.2295177251185,-0.0270645,0.0,basesize};
Point(p++) = {0.2302569668246,-0.0270645,0.0,basesize};
Point(p++) = {0.2309962085308,-0.0270645,0.0,basesize};
Point(p++) = {0.231735450237,-0.0270645,0.0,basesize};
Point(p++) = {0.2324746919431,-0.0270645,0.0,basesize};
Point(p++) = {0.2332139336493,-0.0270645,0.0,basesize};
Point(p++) = {0.2339531753555,-0.0270645,0.0,basesize};
Point(p++) = {0.2346924170616,-0.02679430246686,0.0,basesize};
Point(p++) = {0.2354316587678,-0.0262852999159,0.0,basesize};
Point(p++) = {0.2361709004739,-0.02577629736494,0.0,basesize};
Point(p++) = {0.2369101421801,-0.02526729481398,0.0,basesize};
Point(p++) = {0.2376493838863,-0.02475829226302,0.0,basesize};
Point(p++) = {0.2383886255924,-0.02424928971206,0.0,basesize};
Point(p++) = {0.2391278672986,-0.0237402871611,0.0,basesize};
Point(p++) = {0.2398671090047,-0.02323128461014,0.0,basesize};
Point(p++) = {0.2406063507109,-0.02272228205918,0.0,basesize};
Point(p++) = {0.2413455924171,-0.02221327950822,0.0,basesize};
Point(p++) = {0.2420848341232,-0.02170427695726,0.0,basesize};
Point(p++) = {0.2428240758294,-0.0211952744063,0.0,basesize};
Point(p++) = {0.2435633175355,-0.02068627185534,0.0,basesize};
Point(p++) = {0.2443025592417,-0.02017726930438,0.0,basesize};
Point(p++) = {0.2450418009479,-0.01966826675342,0.0,basesize};
Point(p++) = {0.245781042654,-0.01915926420245,0.0,basesize};
Point(p++) = {0.2465202843602,-0.01865026165149,0.0,basesize};
Point(p++) = {0.2472595260664,-0.01814125910053,0.0,basesize};
Point(p++) = {0.2479987677725,-0.01763225654957,0.0,basesize};
Point(p++) = {0.2487380094787,-0.01712325399861,0.0,basesize};
Point(p++) = {0.2494772511848,-0.01661425144765,0.0,basesize};
Point(p++) = {0.250216492891,-0.01610524889669,0.0,basesize};
Point(p++) = {0.2509557345972,-0.01559624634573,0.0,basesize};
Point(p++) = {0.2516949763033,-0.01508724379477,0.0,basesize};
Point(p++) = {0.2524342180095,-0.01457824124381,0.0,basesize};
Point(p++) = {0.2531734597156,-0.01406923869285,0.0,basesize};
Point(p++) = {0.2539127014218,-0.01356023614189,0.0,basesize};
Point(p++) = {0.254651943128,-0.01305123359093,0.0,basesize};
Point(p++) = {0.2553911848341,-0.01254223104006,0.0,basesize};
Point(p++) = {0.2561304265403,-0.01203324300793,0.0,basesize};
Point(p++) = {0.2568696682464,-0.01153323105766,0.0,basesize};
Point(p++) = {0.2576089099526,-0.01107308263704,0.0,basesize};
Point(p++) = {0.2583481516588,-0.01065403753526,0.0,basesize};
Point(p++) = {0.2590873933649,-0.0102747284778,0.0,basesize};
Point(p++) = {0.2598266350711,-0.009933787576145,0.0,basesize};
Point(p++) = {0.2605658767773,-0.009629846941815,0.0,basesize};
Point(p++) = {0.2613051184834,-0.009361538686311,0.0,basesize};
Point(p++) = {0.2620443601896,-0.009127494921139,0.0,basesize};
Point(p++) = {0.2627836018957,-0.008926347757803,0.0,basesize};
Point(p++) = {0.2635228436019,-0.008756729307808,0.0,basesize};
Point(p++) = {0.2642620853081,-0.008617271682661,0.0,basesize};
Point(p++) = {0.2650013270142,-0.008506606993866,0.0,basesize};
Point(p++) = {0.2657405687204,-0.008423367352927,0.0,basesize};
Point(p++) = {0.2664798104265,-0.008366184871351,0.0,basesize};
Point(p++) = {0.2672190521327,-0.008333691646977,0.0,basesize};
Point(p++) = {0.2679582938389,-0.008324504031647,0.0,basesize};
Point(p++) = {0.268697535545,-0.008324500001239,0.0,basesize};
Point(p++) = {0.2694367772512,-0.0083245,0.0,basesize};
Point(p++) = {0.2701760189573,-0.0083245,0.0,basesize};
Point(p++) = {0.2709152606635,-0.0083245,0.0,basesize};
Point(p++) = {0.2716545023697,-0.0083245,0.0,basesize};
Point(p++) = {0.2723937440758,-0.0083245,0.0,basesize};
Point(p++) = {0.273132985782,-0.0083245,0.0,basesize};
Point(p++) = {0.2738722274882,-0.0083245,0.0,basesize};
Point(p++) = {0.2746114691943,-0.0083245,0.0,basesize};
Point(p++) = {0.2753507109005,-0.0083245,0.0,basesize};
Point(p++) = {0.2760899526066,-0.0083245,0.0,basesize};
Point(p++) = {0.2768291943128,-0.0083245,0.0,basesize};
Point(p++) = {0.277568436019,-0.0083245,0.0,basesize};
Point(p++) = {0.2783076777251,-0.0083245,0.0,basesize};
Point(p++) = {0.2790469194313,-0.0083245,0.0,basesize};
Point(p++) = {0.2797861611374,-0.0083245,0.0,basesize};
Point(p++) = {0.2805254028436,-0.0083245,0.0,basesize};
Point(p++) = {0.2812646445498,-0.0083245,0.0,basesize};
Point(p++) = {0.2820038862559,-0.0083245,0.0,basesize};
Point(p++) = {0.2827431279621,-0.0083245,0.0,basesize};
Point(p++) = {0.2834823696682,-0.0083245,0.0,basesize};
Point(p++) = {0.2842216113744,-0.0083245,0.0,basesize};
Point(p++) = {0.2849608530806,-0.0083245,0.0,basesize};
Point(p++) = {0.2857000947867,-0.0083245,0.0,basesize};
Point(p++) = {0.2864393364929,-0.0083245,0.0,basesize};
Point(p++) = {0.2871785781991,-0.0083245,0.0,basesize};
Point(p++) = {0.2879178199052,-0.0083245,0.0,basesize};
Point(p++) = {0.2886570616114,-0.0083245,0.0,basesize};
Point(p++) = {0.2893963033175,-0.0083245,0.0,basesize};
Point(p++) = {0.2901355450237,-0.0083245,0.0,basesize};
Point(p++) = {0.2908747867299,-0.0083245,0.0,basesize};
Point(p++) = {0.291614028436,-0.0083245,0.0,basesize};
Point(p++) = {0.2923532701422,-0.0083245,0.0,basesize};
Point(p++) = {0.2930925118483,-0.0083245,0.0,basesize};
Point(p++) = {0.2938317535545,-0.0083245,0.0,basesize};
Point(p++) = {0.2945709952607,-0.0083245,0.0,basesize};
Point(p++) = {0.2953102369668,-0.0083245,0.0,basesize};
Point(p++) = {0.296049478673,-0.0083245,0.0,basesize};
Point(p++) = {0.2967887203791,-0.0083245,0.0,basesize};
Point(p++) = {0.2975279620853,-0.0083245,0.0,basesize};
Point(p++) = {0.2982672037915,-0.0083245,0.0,basesize};
Point(p++) = {0.2990064454976,-0.0083245,0.0,basesize};
Point(p++) = {0.2997456872038,-0.0083245,0.0,basesize};
Point(p++) = {0.30048492891,-0.0083245,0.0,basesize};
Point(p++) = {0.3012241706161,-0.0083245,0.0,basesize};
Point(p++) = {0.3019634123223,-0.0083245,0.0,basesize};
Point(p++) = {0.3027026540284,-0.0083245,0.0,basesize};
Point(p++) = {0.3034418957346,-0.0083245,0.0,basesize};
Point(p++) = {0.3041811374408,-0.0083245,0.0,basesize};
Point(p++) = {0.3049203791469,-0.0083245,0.0,basesize};
Point(p++) = {0.3056596208531,-0.0083245,0.0,basesize};
Point(p++) = {0.3063988625592,-0.0083245,0.0,basesize};
Point(p++) = {0.3071381042654,-0.0083245,0.0,basesize};
Point(p++) = {0.3078773459716,-0.0083245,0.0,basesize};
Point(p++) = {0.3086165876777,-0.0083245,0.0,basesize};
Point(p++) = {0.3093558293839,-0.0083245,0.0,basesize};
Point(p++) = {0.31009507109,-0.0083245,0.0,basesize};
Point(p++) = {0.3108343127962,-0.0083245,0.0,basesize};
Point(p++) = {0.3115735545024,-0.0083245,0.0,basesize};
Point(p++) = {0.3123127962085,-0.0083245,0.0,basesize};
Point(p++) = {0.3130520379147,-0.0083245,0.0,basesize};
Point(p++) = {0.3137912796209,-0.0083245,0.0,basesize};
Point(p++) = {0.314530521327,-0.0083245,0.0,basesize};
Point(p++) = {0.3152697630332,-0.0083245,0.0,basesize};
Point(p++) = {0.3160090047393,-0.0083245,0.0,basesize};
Point(p++) = {0.3167482464455,-0.0083245,0.0,basesize};
Point(p++) = {0.3174874881517,-0.0083245,0.0,basesize};
Point(p++) = {0.3182267298578,-0.0083245,0.0,basesize};
Point(p++) = {0.318965971564,-0.0083245,0.0,basesize};
Point(p++) = {0.3197052132701,-0.0083245,0.0,basesize};
Point(p++) = {0.3204444549763,-0.0083245,0.0,basesize};
Point(p++) = {0.3211836966825,-0.0083245,0.0,basesize};
Point(p++) = {0.3219229383886,-0.0083245,0.0,basesize};
Point(p++) = {0.3226621800948,-0.0083245,0.0,basesize};
Point(p++) = {0.3234014218009,-0.0083245,0.0,basesize};
Point(p++) = {0.3241406635071,-0.0083245,0.0,basesize};
Point(p++) = {0.3248799052133,-0.0083245,0.0,basesize};
Point(p++) = {0.3256191469194,-0.0083245,0.0,basesize};
Point(p++) = {0.3263583886256,-0.0083245,0.0,basesize};
Point(p++) = {0.3270976303318,-0.0083245,0.0,basesize};
Point(p++) = {0.3278368720379,-0.0083245,0.0,basesize};
Point(p++) = {0.3285761137441,-0.0083245,0.0,basesize};
Point(p++) = {0.3293153554502,-0.0083245,0.0,basesize};
Point(p++) = {0.3300545971564,-0.0083245,0.0,basesize};
Point(p++) = {0.3307938388626,-0.0083245,0.0,basesize};
Point(p++) = {0.3315330805687,-0.0083245,0.0,basesize};
Point(p++) = {0.3322723222749,-0.0083245,0.0,basesize};
Point(p++) = {0.333011563981,-0.0083245,0.0,basesize};
Point(p++) = {0.3337508056872,-0.0083245,0.0,basesize};
Point(p++) = {0.3344900473934,-0.0083245,0.0,basesize};
Point(p++) = {0.3352292890995,-0.0083245,0.0,basesize};
Point(p++) = {0.3359685308057,-0.0083245,0.0,basesize};
Point(p++) = {0.3367077725118,-0.0083245,0.0,basesize};
Point(p++) = {0.337447014218,-0.0083245,0.0,basesize};
Point(p++) = {0.3381862559242,-0.0083245,0.0,basesize};
Point(p++) = {0.3389254976303,-0.0083245,0.0,basesize};
Point(p++) = {0.3396647393365,-0.0083245,0.0,basesize};
Point(p++) = {0.3404039810427,-0.0083245,0.0,basesize};
Point(p++) = {0.3411432227488,-0.0083245,0.0,basesize};
Point(p++) = {0.341882464455,-0.0083245,0.0,basesize};
Point(p++) = {0.3426217061611,-0.0083245,0.0,basesize};
Point(p++) = {0.3433609478673,-0.0083245,0.0,basesize};
Point(p++) = {0.3441001895735,-0.0083245,0.0,basesize};
Point(p++) = {0.3448394312796,-0.0083245,0.0,basesize};
Point(p++) = {0.3455786729858,-0.0083245,0.0,basesize};
Point(p++) = {0.3463179146919,-0.0083245,0.0,basesize};
Point(p++) = {0.3470571563981,-0.0083245,0.0,basesize};
Point(p++) = {0.3477963981043,-0.0083245,0.0,basesize};
Point(p++) = {0.3485356398104,-0.0083245,0.0,basesize};
Point(p++) = {0.3492748815166,-0.0083245,0.0,basesize};
Point(p++) = {0.3500141232227,-0.0083245,0.0,basesize};
Point(p++) = {0.3507533649289,-0.0083245,0.0,basesize};
Point(p++) = {0.3514926066351,-0.0083245,0.0,basesize};
Point(p++) = {0.3522318483412,-0.0083245,0.0,basesize};
Point(p++) = {0.3529710900474,-0.0083245,0.0,basesize};
Point(p++) = {0.3537103317536,-0.0083245,0.0,basesize};
Point(p++) = {0.3544495734597,-0.0083245,0.0,basesize};
Point(p++) = {0.3551888151659,-0.0083245,0.0,basesize};
Point(p++) = {0.355928056872,-0.0083245,0.0,basesize};
Point(p++) = {0.3566672985782,-0.0083245,0.0,basesize};
Point(p++) = {0.3574065402844,-0.0083245,0.0,basesize};
Point(p++) = {0.3581457819905,-0.0083245,0.0,basesize};
Point(p++) = {0.3588850236967,-0.0083245,0.0,basesize};
Point(p++) = {0.3596242654028,-0.0083245,0.0,basesize};
Point(p++) = {0.360363507109,-0.0083245,0.0,basesize};
Point(p++) = {0.3611027488152,-0.0083245,0.0,basesize};
Point(p++) = {0.3618419905213,-0.0083245,0.0,basesize};
Point(p++) = {0.3625812322275,-0.0083245,0.0,basesize};
Point(p++) = {0.3633204739336,-0.0083245,0.0,basesize};
Point(p++) = {0.3640597156398,-0.0083245,0.0,basesize};
Point(p++) = {0.364798957346,-0.0083245,0.0,basesize};
Point(p++) = {0.3655381990521,-0.0083245,0.0,basesize};
Point(p++) = {0.3662774407583,-0.0083245,0.0,basesize};
Point(p++) = {0.3670166824645,-0.0083245,0.0,basesize};
Point(p++) = {0.3677559241706,-0.0083245,0.0,basesize};
Point(p++) = {0.3684951658768,-0.0083245,0.0,basesize};
Point(p++) = {0.3692344075829,-0.0083245,0.0,basesize};
Point(p++) = {0.3699736492891,-0.0083245,0.0,basesize};
Point(p++) = {0.3707128909953,-0.0083245,0.0,basesize};
Point(p++) = {0.3714521327014,-0.0083245,0.0,basesize};
Point(p++) = {0.3721913744076,-0.0083245,0.0,basesize};
Point(p++) = {0.3729306161137,-0.0083245,0.0,basesize};
Point(p++) = {0.3736698578199,-0.0083245,0.0,basesize};
Point(p++) = {0.3744090995261,-0.0083245,0.0,basesize};
Point(p++) = {0.3751483412322,-0.0083245,0.0,basesize};
Point(p++) = {0.3758875829384,-0.0083245,0.0,basesize};
Point(p++) = {0.3766268246445,-0.0083245,0.0,basesize};
Point(p++) = {0.3773660663507,-0.0083245,0.0,basesize};
Point(p++) = {0.3781053080569,-0.0083245,0.0,basesize};
Point(p++) = {0.378844549763,-0.0083245,0.0,basesize};
Point(p++) = {0.3795837914692,-0.0083245,0.0,basesize};
Point(p++) = {0.3803230331754,-0.0083245,0.0,basesize};
Point(p++) = {0.3810622748815,-0.0083245,0.0,basesize};
Point(p++) = {0.3818015165877,-0.0083245,0.0,basesize};
Point(p++) = {0.38328,-0.0083245,0.0,basesize};
p_nozzle_bottom_end = p-1;

y_isolator_top = 0.01167548819733;
y_isolator_bottom = -0.0083245;

//Make Lines
//Bottom
l_nozzle_top = l++;
Spline(l_nozzle_top) = {p_nozzle_top_start:p_nozzle_top_end};
//Bottom
l_nozzle_bottom = l++;
Spline(l_nozzle_bottom) = {p_nozzle_bottom_start:p_nozzle_bottom_end}; // goes counter-clockwise

bl_thickness = 0.0015;
bl_thickness_inj = 0.0005;
top_bl_line[] = Translate { 0., -bl_thickness, 0.} {Duplicata{ Line{l_nozzle_top}; } };
bottom_bl_line[] = Translate { 0., bl_thickness, 0.} {Duplicata{ Line{l_nozzle_bottom}; } };
top_bl_points[] = Boundary{ Line{top_bl_line[0]}; };
bottom_bl_points[] = Boundary{ Line{bottom_bl_line[0]}; };

//Printf("top_bl_line length = %g", #top_bl_line[]);
//For i In {0:#top_bl_line[]-1}
    //Printf("top_bl_line: %g",top_bl_line[i]);
//EndFor

//Printf("top_bl_points length = %g", #top_bl_points[]);
//For i In {0:#top_bl_points[]-1}
    //Printf("top_bl_points: %g",top_bl_points[i]);
//EndFor

//Printf("bottom_bl_line length = %g", #bottom_bl_line[]);
//For i In {0:#bottom_bl_line[]-1}
    //Printf("bottom_bl_line: %g",bottom_bl_line[i]);
//EndFor

//Printf("bottom_bl_points length = %g", #bottom_bl_points[]);
//For i In {0:#bottom_bl_points[]-1}
    //Printf("bottom_bl_points: %g",bottom_bl_points[i]);
//EndFor

l_nozzle_top_bl = top_bl_line[0];
l_nozzle_bottom_bl = bottom_bl_line[0];

p_nozzle_top_bl_start = top_bl_points[0];
p_nozzle_top_bl_end = top_bl_points[#top_bl_points[]-1];
p_nozzle_bottom_bl_start = bottom_bl_points[0];
p_nozzle_bottom_bl_end = bottom_bl_points[#bottom_bl_points[]-1];

// Make the back surface
// Inlet
l = l_nozzle_bottom_bl + 1;
//Printf("l = %g", l);
l_nozzle_top_bl_inlet = l++;
//Printf("l_nozzle_top_bl_inlet = %g", l_nozzle_top_bl_inlet);
Line(l_nozzle_top_bl_inlet) = {p_nozzle_top_start, p_nozzle_top_bl_start};
l_nozzle_inlet = l++;
Line(l_nozzle_inlet) = {p_nozzle_top_bl_start, p_nozzle_bottom_bl_start};
l_nozzle_bottom_bl_inlet = l++;
Line(l_nozzle_bottom_bl_inlet) = {p_nozzle_bottom_bl_start, p_nozzle_bottom_start};

// Outlet
l_nozzle_top_bl_outlet = l++;
Line(l_nozzle_top_bl_outlet) = {p_nozzle_top_end, p_nozzle_top_bl_end};
l_nozzle_outlet = l++;
Line(l_nozzle_outlet) = {p_nozzle_top_bl_end, p_nozzle_bottom_bl_end};
l_nozzle_bottom_bl_outlet = l++;
Line(l_nozzle_bottom_bl_outlet) = {p_nozzle_bottom_bl_end, p_nozzle_bottom_end};


//Create lineloop of this geometry
// start on the bottom left and go around clockwise
Curve Loop(100) = { 
    l_nozzle_top_bl_inlet,
    l_nozzle_top,
    l_nozzle_top_bl_outlet,
    l_nozzle_top_bl
}; 
Plane Surface(100) = {100}; // the back wall top bl

Curve Loop(200) = { 
    l_nozzle_bottom_bl_inlet,
    l_nozzle_bottom_bl,
    l_nozzle_bottom_bl_outlet,
    l_nozzle_bottom
}; 
Plane Surface(200) = {200}; // the back wall bottom bl

Curve Loop(300) = { 
    l_nozzle_inlet,
    l_nozzle_top_bl,
    l_nozzle_outlet,
    l_nozzle_bottom_bl
}; 
Plane Surface(300) = {300}; /// the back wall interior

/////////////////////////////////////////////
// Extrude the back surfaces into volumes,
// aft bl, interior, and fore-bl
/////////////////////////////////////////////

// surfaceVector contains in the following order:
// [0]	- front surface (opposed to source surface)
// [1] - extruded volume
// [n+1] - surfaces (belonging to nth line in "Curve Loop (1)") */
// aft bl
surface_vector_top_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{100}; };
surface_vector_bottom_bl_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{200}; };
surface_vector_interior_aft_bl[] = Extrude {0, 0, bl_thickness} { Surface{300}; };

// fore-aft interior
surface_vector_interior_top_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{surface_vector_top_bl_aft_bl[0]};};
surface_vector_interior_bottom_bl[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{surface_vector_bottom_bl_aft_bl[0]};};
surface_vector_interior[] = Extrude {0, 0, 0.035 - 2*bl_thickness} { Surface{surface_vector_interior_aft_bl[0]};};

// fore bl
surface_vector_top_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{surface_vector_interior_top_bl[0]};};
surface_vector_bottom_bl_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{surface_vector_interior_bottom_bl[0]};};
surface_vector_interior_fore_bl[] = Extrude {0, 0, bl_thickness} { Surface{surface_vector_interior[0]};};
//


fluid_volume[] = Volume In BoundingBox {
    -1., -1., -1., 2., 1., 1.
};
//
Physical Volume("fluid_domain") = {
    fluid_volume[]
};

Coherence; // remove duplicate entities

///////////////////////////////////////////////
// edge idenfication for transfinite meshing //
///////////////////////////////////////////////
//
// anywhere below this that uses a hard-coded number is wrong
// detect the surface/edge numbering through bounding box manipulation
//
x_isolator_start = 0.38328;
y_isolator_top = 0.01167548819733;
y_isolator_bottom = -0.0083245;
box_tol = 0.0001;

// given an array of edges, find their proper orientation
// according to the array orient based on the orientation of the
// point coordinates
// bb is the bounding box for the volume we're querying
Macro EdgeAndSurfaces

    // x0 end
    begin_save = bb[0];
    end_save = bb[3];

    bb[0] = begin_save - box_tol;
    bb[3] = begin_save + box_tol;
    surfaces[] = Surface In BoundingBox {bb[]};
    edges[] = Curve In BoundingBox { bb[] };

    // loop over all edges to determine orientation
    For j In {0:#edges[]-1}
        edge_points[] = PointsOf{Line{edges[j]};};
        p1[]=Point{edge_points[0]};
        p2[]=Point{edge_points[1]};
    
        For k In {0:2}
            If (Abs(p1[k] - p2[k]) > 1.e-10)
                If ((p1[k] - p2[k]) > 1.e-10)
                    edges[j] *= -1*edge_orient[k];
                Else
                    edges[j] *= edge_orient[k];
                EndIf
            EndIf
        EndFor
    EndFor

    bb[0] = end_save - box_tol;
    bb[3] = end_save + box_tol;
    surfaces[] += Surface In BoundingBox {bb[]};
    edges2[] = Curve In BoundingBox { bb[] };

    // loop over all edges to determine orientation
    For j In {0:#edges2[]-1}
        edge_points[] = PointsOf{Line{edges2[j]};};
        p1[]=Point{edge_points[0]};
        p2[]=Point{edge_points[1]};
    
        For k In {0:2}
            If (Abs(p1[k] - p2[k]) > 1.e-10)
                If ((p1[k] - p2[k]) > 1.e-10)
                    edges2[j] *= -1*edge_orient[k];
                Else
                    edges2[j] *= edge_orient[k];
                EndIf
            EndIf
        EndFor
    EndFor

    edges[] += edges2[];

Return

// fore/aft/top/bottom corners
//  aft-bottom
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{surface_vector_bottom_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] = edges[];
bl_corner_surfaces[] = surfaces[];

//fore-bottom
edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{surface_vector_bottom_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// aft-top
edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{surface_vector_top_bl_aft_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];

// fore-top
edge_orient[] = {1, -1, -1};
bb[] = BoundingBox Volume{surface_vector_top_bl_fore_bl[1]};
Call EdgeAndSurfaces;
bl_corner_vert_edges[] += edges[];
bl_corner_surfaces[] += surfaces[];
    
Printf("bl_corner_vert_edges length = %g", #bl_corner_vert_edges[]);
For i In {0:#bl_corner_vert_edges[]-1}
    Printf("bl_corner_vert_edges: %g",bl_corner_vert_edges[i]);
EndFor
Printf("bl_corner_surfaces length = %g", #bl_corner_surfaces[]);
For i In {0:#bl_corner_surfaces[]-1}
    Printf("bl_corner_surfaces: %g",bl_corner_surfaces[i]);
EndFor



//  fore/aft/top/bottom side planes/edges
//  we don't need the orientation information here, so just remove it so we can easily subtract the 
//  corner edges
//  bottom
edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{surface_vector_interior_bottom_bl[1]};
Call EdgeAndSurfaces;
bl_bottom_edges[] = Abs(edges[]);
bl_bottom_surfaces[] = surfaces[];

// top
//edge_orient[] = {1, -1, 1};
bb[] = BoundingBox Volume{surface_vector_interior_top_bl[1]};
Call EdgeAndSurfaces;
bl_top_edges[] = Abs(edges[]);
bl_top_surfaces[] = surfaces[];

// aft
//edge_orient[] = {1, 1, -1};
bb[] = BoundingBox Volume{surface_vector_interior_aft_bl[1]};
Call EdgeAndSurfaces;
bl_aft_edges[] = Abs(edges[]);
bl_aft_surfaces[] = surfaces[];

// fore
//edge_orient[] = {1, 1, 1};
bb[] = BoundingBox Volume{surface_vector_interior_fore_bl[1]};
Call EdgeAndSurfaces;
bl_fore_edges[] = Abs(edges[]);
bl_fore_surfaces[] = surfaces[];

// remove the short edges
//
bl_fore_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_aft_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_top_edges[] -= Abs(bl_corner_vert_edges[]); 
bl_bottom_edges[] -= Abs(bl_corner_vert_edges[]); 

Printf("bl_aft_edges length = %g", #bl_aft_edges[]);
Printf("bl_fore_edges length = %g", #bl_fore_edges[]);
Printf("bl_top_edges length = %g", #bl_top_edges[]);
Printf("bl_bottom_edges length = %g", #bl_bottom_edges[]);
For i In {0:#bl_aft_edges[]-1}
    Printf("bl_aft_edges: %g",bl_aft_edges[i]);
EndFor
Printf("bl_aft_surfaces length = %g", #bl_aft_surfaces[]);
For i In {0:#bl_aft_surfaces[]-1}
    Printf("bl_aft_surfaces: %g",bl_aft_surfaces[i]);
EndFor

//
// long corner edges
// we can construct from the already discovered edges and the existing volumes
// 
bl_long_surfaces[] = Surface In BoundingBox { BoundingBox Volume{ surface_vector_top_bl_aft_bl[1]} };
bl_long_surfaces[] += Surface In BoundingBox { BoundingBox Volume{ surface_vector_bottom_bl_aft_bl[1]} };
bl_long_surfaces[] += Surface In BoundingBox { BoundingBox Volume{ surface_vector_top_bl_fore_bl[1]} };
bl_long_surfaces[] += Surface In BoundingBox { BoundingBox Volume{ surface_vector_bottom_bl_fore_bl[1]} };

// remove the end surfaces
bl_long_surfaces[] -= bl_corner_surfaces[];

// get the edges
For i In {0:#bl_long_surfaces[]-1}
    bl_long_edges[] += Curve In BoundingBox { BoundingBox Surface{ bl_long_surfaces[i] } };
EndFor

// remove the end surfaces
bl_long_edges[] = Unique(bl_long_edges[]);
bl_long_edges[] -= Abs(bl_corner_vert_edges[]);

Printf("bl_long_edges length = %g", #bl_long_edges[]);
For i In {0:#bl_long_edges[]-1}
    Printf("bl_long_edges: %g",bl_long_edges[i]);
EndFor
Printf("bl_long_surfaces length = %g", #bl_long_surfaces[]);
For i In {0:#bl_long_surfaces[]-1}
    Printf("bl_long_surfaces: %g",bl_long_surfaces[i]);
EndFor
//
// get the exterior surfaces of all the volumes
//
exterior_surfaces[] = CombinedBoundary { Volume {fluid_volume[]}; };
interior_surfaces[] = Boundary { Volume { surface_vector_interior[1]}; };
 remove the inlet/outlet planes
interior_surfaces[] -= exterior_surfaces[];
Printf("exterior_surfaces length = %g", #exterior_surfaces[]);
For i In {0:#exterior_surfaces[]-1}
    Printf("exterior_surfaces: %g",exterior_surfaces[i]);
EndFor
Printf("interior_surfaces length = %g", #interior_surfaces[]);
For i In {0:#interior_surfaces[]-1}
    Printf("interior_surfaces: %g",interior_surfaces[i]);
EndFor

/////////////////////
// Apply  meshing 
////////////////////

// end edges and surfaces defining the corner bl meshes, fore/aft/top/bottom on the inlet/outlet planes
Transfinite Curve {
    bl_corner_vert_edges[]
} = 7 Using Progression 1.2;
//} = 10;

Transfinite Surface {
    bl_corner_surfaces[]
};

// end edges defining the fore and aft bl meshes,
Transfinite Curve {
    bl_fore_edges[],
    bl_aft_edges[]
} = 25 Using Bump 0.35;
//} = 25;

Transfinite Surface {
    bl_fore_surfaces[],
    bl_aft_surfaces[]
};

// end edges defining the top and bottom bl meshes,
Transfinite Curve {
    bl_bottom_edges[],
    bl_top_edges[]
} = 35 Using Bump 0.35;
//} = 35;

Transfinite Surface {
    bl_bottom_surfaces[],
    bl_top_surfaces[]
};

// end edges defining the top and bottom bl meshes,
Transfinite Curve {
    bl_long_edges[]
} = 150;

Transfinite Surface {
    bl_long_surfaces[]
};

// setup structured bl meshes
// setup structured bl meshes
// long edges along nozzle
//Transfinite Curve {
    //12, 11, 7, 6,
    //54, 36, 33, 51,
    //18, 19, 23, 24,
    //62, 41, 59, 44
//} = 200;

// vertical edges on inlet and outlet
//Transfinite Curve {
    //25, 26, 45, 63,   // inlet
    //27, 28, 46, 64 // outlet
//} = 25 Using Bump 0.35;

// horizontal edges on inlet and outlet
//Transfinite Curve {
    //29, 30, 37, 38, // inlet
    //40, 42, 32, 34  // outlet
//} = 35 Using Bump 0.35;

// end edges defining the bl meshes, fore/aft/top/bottom on the inlet/outlet planes
//Transfinite Curve {
    ////5, 13, 37, 61,  // top bl on the inlet
    ////-7, -21, -45, -69,  // bottom bl on the inlet
    ////11, 12, 19, 20, // aft bl on the inlet
    ////-59, -60, -67, -68, // fore bl on the inlet
    ////65, 41, 17, 8,  // top bl on the outlet
    ////-73, -49, -25, -10, // bottom bl on the outlet
    ////16, 14, 24, 22, // fore bl on the outlet
    ////-62, -64, -72, -70  // aft bl on the outlet
    ////
    //3, 4, 31, 49,      // top bl on the inlet
    //-15, -16, -39, -57,// bottom bl on the inlet
    //1, 2, 13, 14,      // aft bl on the inlet
    //-47, -48, -55, -56,// fore bl on the inlet
    //9, 10, 35, 53,     // top bl on the outlet
    //-21, -22, -43, -61,// bottom bl on the outlet
    //-58, -60, -50, -52,    // fore bl on the outlet
    //17, 20, 5, 8   // aft bl on the outlet
//} = 10 Using Progression 1.2;

// surfaces of the corner bl volumes
//Transfinite Surface {
    //1:6,      // top-aft
    //7:12,     // bottom-aft
    //21,30:34, // top-fore
    //26,35:39  // bottom-fore
//};

//// surface of the side bl volumes
//Transfinite Surface {
    //// all four planes
    ////13:16,      // aft
    ////29,40:42,   // fore
    ////22:25,      // bottom
    ////17:20       // top
    //// only the end planes
    //13, 14,      // aft
    //40, 41,      // fore
    //22, 24,      // bottom
    //17, 19       // top
//};
nozzle_start = 0.27;
nozzle_end = 0.30;

// Create distance field from surfaces for wall meshing, excludes cavity, injector
Field[1] = Distance;
//Field[1].SurfacesList = {
    //15, 42, 20, 23
Field[1].CurvesList = {
    //54, 11, 59, 18
    bl_long_edges[]
};
Field[1].Sampling = 1000;
//
//Create threshold field that varrries element size near boundaries
Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = isosize / boundratio;
Field[2].SizeMax = isosize;
Field[2].DistMin = 0.0002;
//Field[2].DistMax = 0.005;
Field[2].DistMax = 0.015;
Field[2].StopAtDistMax = 1;

//  background mesh size in the isolator (downstream of the nozzle)
Field[3] = Box;
Field[3].XMin = nozzle_end;
Field[3].XMax = 1.0;
Field[3].YMin = -1.0;
Field[3].YMax = 1.0;
Field[3].ZMin = -1.0;
Field[3].ZMax = 1.0;
Field[3].VIn = isosize;
Field[3].VOut = bigsize;

// background mesh size upstream of the inlet
Field[4] = Box;
Field[4].XMin = 0.;
Field[4].XMax = nozzle_start;
Field[4].YMin = -1.0;
Field[4].YMax = 1.0;
Field[4].ZMin = -1.0;
Field[4].ZMax = 1.0;
Field[4].VIn = inletsize;
Field[4].VOut = bigsize;

// background mesh size in the nozzle throat
Field[5] = Box;
Field[5].XMin = nozzle_start;
Field[5].XMax = nozzle_end;
Field[5].YMin = -1.0;
Field[5].YMax = 1.0;
Field[5].ZMin = -1.0;
Field[5].ZMax = 1.0;
Field[5].Thickness = 0.10;    // interpolate from VIn to Vout over a distance around the box
Field[5].VIn = nozzlesize;
Field[5].VOut = bigsize;

// take the minimum of all defined meshing fields
//
Field[100] = Min;
//Field[100].FieldsList = {2, 3, 4, 5, 6, 7, 8, 12, 14};
Field[100].FieldsList = {2, 3, 4, 5};
Background Field = 100;

Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 0;
Mesh.MeshSizeFromCurvature = 0;


// Delaunay, seems to respect changing mesh sizes better
// Mesh.Algorithm3D = 1; 
// Frontal, makes a better looking mesh, will make bigger elements where I don't want them though
// Doesn't repsect the mesh sizing parameters ...
//Mesh.Algorithm3D = 4; 
// HXT, re-implemented Delaunay in parallel
Mesh.Algorithm3D = 10; 
//Mesh.OptimizeNetgen = 1;
//Mesh.Smoothing = 100;
