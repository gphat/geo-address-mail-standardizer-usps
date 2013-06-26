package Geo::Address::Mail::Standardizer::USPS;
use Moose;

with 'Geo::Address::Mail::Standardizer';

our $VERSION = '0.03';

use Geo::Address::Mail::Standardizer::Results;

# Defined in C2 - "Secondary Unit Designators"
my %range_designators = (
    APT  => qr/(?:^|\b)AP(?:T|ARTMENT)\.?(?:\b|$)/i,
    BLDG => qr/(?:^|\b)B(?:UI)?LD(?:IN)?G\.?(?:\b|$)/i,
    DEPT => qr/(?:^|\b)DEP(?:ARTMEN)?T\.?(?:\b|$)/i,
    FL   => qr/(?:^|\b)FL(?:OOR)?\.?(?:\b|$)/i,
    HNGR => qr/(?:^|\b)HA?NGE?R\.?(?:\b|$)/i,
    KEY  => qr/(?:^|\b)KEY\.?(?:\b|$)/i,
    LOT  => qr/(?:^|\b)LOT\.?(?:\b|$)/i,
    PIER => qr/(?:^|\b)PIER\.?(?:\b|$)/i,
    RM   => qr/(?:^|\b)R(?:OO)?M\.?(?:\b|$)/i,
    SLIP => qr/(?:^|\b)SLIP\.?(?:\b|$)/i,
    SPC  => qr/(?:^|\b)SPA?CE?\.?(?:\b|$)/i,
    STOP => qr/(?:^|\b)STOP\.?(?:\b|$)/i,
    STE  => qr/(?:^|\b)S(?:UI)?TE\.?(?:\b|$)/i,
    TRLR => qr/(?:^|\b)TR(?:AI)?LE?R\.?(?:\b|$)/i,
    UNIT => qr/(?:^|\b)UNIT\.?(?:\b|$)/i,
);

# Defined in C2 - "Secondary Unit Designators", does not require secondary
# RANGE to follow.
my %designators = (
    BSMT => qr/(?:^|\b)BA?SE?M(?:EN)?T\.?(?:\b|$)/i,
    FRNT => qr/(?:^|\b)FRO?NT\.?(?:\b|$)/i,
    LBBY => qr/(?:^|\b)LO?BBY\.?(?:\b|$)/i,
    LOWR => qr/(?:^|\b)LOWE?R\.?(?:\b|$)/i,
    OFC  => qr/(?:^|\b)OF(?:FI)?CE?\.?(?:\b|$)/i,
    PH   => qr/(?:^|\b)P(?:ENT)?H(?:OUSE)?\.?(?:\b|$)/i,
    REAR => qr/(?:^|\b)REAR\.?(?:\b|$)/i,
    SIDE => qr/(?:^|\b)SIDE\.?(?:\b|$)/i,
    UPPR => qr/(?:^|\b)UPPE?R\.?(?:\b|$)/i,
);

# Defined in C1 - "Street Suffix Abbreviations"
my %street_suffix_abbrev = (
    ALY  => qr/(?:^|\b)AL+E*Y?\.?(?:\b|(?=\s)|$)/i,
    ANX  => qr/(?:^|\b)AN+E*X\.?(?:\b|(?=\s)|$)/i,
    ARC  => qr/(?:^|\b)ARC(?:ADE)?\.?(?:\b|(?=\s)|$)/i,
    AVE  => qr/(?:^|\b)AVE?(?:N(?:U(?:E)?)?)?\.?(?:\b|(?=\s)|$)/i,
    BYU  => qr/(?:^|\b)(?:BYU|BA?YO*[OU])\.?(?:\b|(?=\s)|$)/i,
    BCH  => qr/(?:^|\b)B(?:EA)?CH\.?(?:\b|(?=\s)|$)/i,
    BND  => qr/(?:^|\b)BE?ND\.?(?:\b|(?=\s)|$)/i,
    BLF  => qr/(?:^|\b)BLU?F+(?!S)\.?(?:\b|(?=\s)|$)/i,
    BLFS => qr/(?:^|\b)BLU?F+S\.?(?:\b|(?=\s)|$)/i,
    BTM  => qr/(?:^|\b)B(?:O?T+O?M|OT)\.?(?:\b|(?=\s)|$)/i,
    BLVD => qr/(?:^|\b)B(?:(?:OU)?LE?V(?:AR)?D|OULV?)\.?(?:\b|(?=\s)|$)/i,
    BR   => qr/(?:^|\b)BR(?:(?:A?NCH)|\.?)(?:\b|(?=\s)|$)/i,
    BRG  => qr/(?:^|\b)BRI?D?GE?\.?(?:\b|(?=\s)|$)/i,
    BRK  => qr/(?:^|\b)BRO*K(?!S)\.?(?:\b|(?=\s)|$)/i,
    BRKS => qr/(?:^|\b)BRO*KS\.?(?:\b|(?=\s)|$)/i,
    BG   => qr/(?:^|\b)B(?:UR)?G(?!S)\.?(?:\b|(?=\s)|$)/i,
    BGS  => qr/(?:^|\b)B(?:UR)?GS\.?(?:\b|(?=\s)|$)/i,
    BYP  => qr/(?:^|\b)BYP(?:A?S*)?\.?(?:\b|(?=\s)|$)/i,
    CP   => qr/(?:^|\b)CA?M?P(?!E)\.?(?:\b|(?=\s)|$)/i,
    CYN  => qr/(?:^|\b)CA?N?YO?N\.?(?:\b|(?=\s)|$)/i,
    CPE  => qr/(?:^|\b)CA?PE\.?(?:\b|(?=\s)|$)/i,
    CSWY => qr/(?:^|\b)C(?:AU)?SE?WA?Y\.?(?:\b|(?=\s)|$)/i,
    CTR  => qr/(?:^|\b)C(?:E?N?TE?RE?|ENT)(?!S)\.?(?:\b|(?=\s)|$)/i,
    CTRS => qr/(?:^|\b)C(?:E?N?TE?RE?|ENT)S\.?(?:\b|(?=\s)|$)/i,
    CIR  => qr/(?:^|\b)C(?:RCLE?|IRC?L?E?)(?!S)\.?(?:\b|(?=\s)|$)/i,
    CIRS => qr/(?:^|\b)C(?:RCLE?|IRC?L?E?)S\.?(?:\b|(?=\s)|$)/i,
    CLF  => qr/(?:^|\b)CLI?F+(?!S)\.?(?:\b|(?=\s)|$)/i,
    CLFS => qr/(?:^|\b)CLI?F+S\.?(?:\b|(?=\s)|$)/i,
    CLB  => qr/(?:^|\b)CLU?B\.?(?:\b|(?=\s)|$)/i,
    CMN  => qr/(?:^|\b)CO?M+O?N\.?(?:\b|(?=\s)|$)/i,
    COR  => qr/(?:^|\b)COR(?:NER)?(?!S)\.?(?:\b|(?=\s)|$)/i,
    CORS => qr/(?:^|\b)COR(?:NER)?S\.?(?:\b|(?=\s)|$)/i,
    CRSE => qr/(?:^|\b)C(?:OU)?RSE\.?(?:\b|(?=\s)|$)/i,
    CT   => qr/(?:^|\b)C(?:OU)?R?T(?![RS])\.?(?:\b|(?=\s)|$)/i,
    CTS  => qr/(?:^|\b)C(?:OU)?R?TS\.?(?:\b|(?=\s)|$)/i,
    CV   => qr/(?:^|\b)CO?VE?(?!S)\.?(?:\b|(?=\s)|$)/i,
    CVS  => qr/(?:^|\b)CO?VE?S\.?(?:\b|(?=\s)|$)/i,
    CRK  => qr/(?:^|\b)C(?:RE*K|[RK])\.?(?:\b|(?=\s)|$)/i,
    CRES => qr/(?:^|\b)CR(?:ES?C?E?(?:NT)?|SC?E?NT|R[ES])\.?(?:\b|(?=\s)|$)/i,
    CRST => qr/(?:^|\b)CRE?ST\.?(?:\b|(?=\s)|$)/i,
    XING => qr/(?:^|\b)(?:CRO?S+I?NG|XING)\.?(?:\b|(?=\s)|$)/i,
    XRD  => qr/(?:^|\b)(?:CRO?S+R(?:OA)?D|XR(?:OA)?D)\.?(?:\b|(?=\s)|$)/i,
    CURV => qr/(?:^|\b)CURVE?\.?(?:\b|(?=\s)|$)/i,
    DL   => qr/(?:^|\b)DA?LE?\.?(?:\b|(?=\s)|$)/i,
    DM   => qr/(?:^|\b)DA?M\.?(?:\b|(?=\s)|$)/i,
    DV   => qr/(?:^|\b)DI?V(?:I?DE?)?\.?(?:\b|(?=\s)|$)/i,
    DR   => qr/(?:^|\b)DR(?:I?VE?)?(?!S)\.?(?:\b|(?=\s)|$)/i,
    DRS  => qr/(?:^|\b)DR(?:I?VE?)?S\.?(?:\b|(?=\s)|$)/i,
    EST  => qr/(?:^|\b)EST(?:ATE)?(?!S)\.?(?:\b|(?=\s)|$)/i,
    ESTS => qr/(?:^|\b)EST(?:ATE)?S\.?(?:\b|(?=\s)|$)/i,
    EXPY => qr/(?:^|\b)EXP(?:R(?:ES+(?:WAY)?)?|[WY])?\.?(?:\b|(?=\s)|$)/i,
    EXT  => qr/(?:^|\b)EXT(?:E?N(?:S(?:IO)?N)?)?(?!S)\.?(?:\b|(?=\s)|$)/i,
    EXTS => qr/(?:^|\b)EXT(?:E?N(?:S(?:IO)?N)?)?S\.?(?:\b|(?=\s)|$)/i,
    FALL => qr/(?:^|\b)FALL(?!S)\.?(?:\b|(?=\s)|$)/i,
    FLS  => qr/(?:^|\b)FA?L+S\.?(?:\b|(?=\s)|$)/i,
    FRY  => qr/(?:^|\b)FE?R+Y\.?(?:\b|(?=\s)|$)/i,
    FLD  => qr/(?:^|\b)F(?:IE)?LD(?!S)\.?(?:\b|(?=\s)|$)/i,
    FLDS => qr/(?:^|\b)F(?:IE)?LDS\.?(?:\b|(?=\s)|$)/i,
    FLT  => qr/(?:^|\b)FLA?T(?!S)\.?(?:\b|(?=\s)|$)/i,
    FLTS => qr/(?:^|\b)FLA?TS\.?(?:\b|(?=\s)|$)/i,
    FRD  => qr/(?:^|\b)FO?RD(?!S)\.?(?:\b|(?=\s)|$)/i,
    FRDS => qr/(?:^|\b)FO?RDS\.?(?:\b|(?=\s)|$)/i,
    FRST => qr/(?:^|\b)FO?RE?STS?\.?(?:\b|(?=\s)|$)/i,
    FRG  => qr/(?:^|\b)FO?RGE?(?!S)\.?(?:\b|(?=\s)|$)/i,
    FRGS => qr/(?:^|\b)FO?RGE?S\.?(?:\b|(?=\s)|$)/i,
    FRK  => qr/(?:^|\b)FO?RK(?!S)\.?(?:\b|(?=\s)|$)/i,
    FRKS => qr/(?:^|\b)FO?RKS\.?(?:\b|(?=\s)|$)/i,
    FT   => qr/(?:^|\b)FO?R?T(?!S)\.?(?:\b|(?=\s)|$)/i,
    FWY  => qr/(?:^|\b)F(?:RE*)?WA?Y\.?(?:\b|(?=\s)|$)/i,
    GDN  => qr/(?:^|\b)G(?:A?R)?DE?N(?!S)\.?(?:\b|(?=\s)|$)/i,
    GDNS => qr/(?:^|\b)G(?:A?R)?DE?NS\.?(?:\b|(?=\s)|$)/i,
    GTWY => qr/(?:^|\b)GA?TE?WA?Y\.?(?:\b|(?=\s)|$)/i,
    GLN  => qr/(?:^|\b)GLE?N(?!S)\.?(?:\b|(?=\s)|$)/i,
    GLNS => qr/(?:^|\b)GLE?NS\.?(?:\b|(?=\s)|$)/i,
    GRN  => qr/(?:^|\b)GRE*N(?!S)\.?(?:\b|(?=\s)|$)/i,
    GRNS => qr/(?:^|\b)GRE*NS\.?(?:\b|(?=\s)|$)/i,
    GRV  => qr/(?:^|\b)GRO?VE?(?!S)\.?(?:\b|(?=\s)|$)/i,
    GRVS => qr/(?:^|\b)GRO?VE?S\.?(?:\b|(?=\s)|$)/i,
    HBR  => qr/(?:^|\b)H(?:(?:A?R)?BO?R|ARB)(?!S)\.?(?:\b|(?=\s)|$)/i,
    HBRS => qr/(?:^|\b)H(?:A?R)?BO?RS\.?(?:\b|(?=\s)|$)/i,
    HVN  => qr/(?:^|\b)HA?VE?N\.?(?:\b|(?=\s)|$)/i,
    HTS  => qr/(?:^|\b)H(?:(?:EI)?GH?)?TS?\.?(?:\b|(?=\s)|$)/i,
    HWY  => qr/(?:^|\b)HI?(?:GH?)?WA?Y\.?(?:\b|(?=\s)|$)/i,
    HL   => qr/(?:^|\b)HI?L+(?![A-Z])\.?(?:\b|(?=\s)|$)/i,
    HLS  => qr/(?:^|\b)HI?L+S\.?(?:\b|(?=\s)|$)/i,
    HOLW => qr/(?:^|\b)HO?L+O?WS?\.?(?:\b|(?=\s)|$)/i,
    INLT => qr/(?:^|\b)INLE?T\.?(?:\b|(?=\s)|$)/i,
    IS   => qr/(?:^|\b)IS(?:LA?ND)?(?![A-Z])\.?(?:\b|(?=\s)|$)/i,
    ISS  => qr/(?:^|\b)IS(?:LA?ND)?S\.?(?:\b|(?=\s)|$)/i,
    ISLE => qr/(?:^|\b)ISLES?\.?(?:\b|(?=\s)|$)/i,
    JCT  => qr/(?:^|\b)JU?N?CT(?:(?:I?O)?N)?(?!S)\.?(?:\b|(?=\s)|$)/i,
    JCTS => qr/(?:^|\b)JU?N?CT(?:(?:I?O)?N)?S\.?(?:\b|(?=\s)|$)/i,
    KY   => qr/(?:^|\b)KE?Y(?!S)\.?(?:\b|(?=\s)|$)/i,
    KYS  => qr/(?:^|\b)KE?YS\.?(?:\b|(?=\s)|$)/i,
    KNL  => qr/(?:^|\b)KNO?L+(?!S)\.?(?:\b|(?=\s)|$)/i,
    KNLS => qr/(?:^|\b)KNO?L+S\.?(?:\b|(?=\s)|$)/i,
    LK   => qr/(?:^|\b)LA?KE?(?!S)\.?(?:\b|(?=\s)|$)/i,
    LKS  => qr/(?:^|\b)LA?KE?S\.?(?:\b|(?=\s)|$)/i,
    LAND => qr/(?:^|\b)LAND(?![A-Z])\.?(?:\b|(?=\s)|$)/i,
    LNDG => qr/(?:^|\b)LA?ND(?:I?N)?G\.?(?:\b|(?=\s)|$)/i,
    LN   => qr/(?:^|\b)L(?:A?NES?|[AN])\.?(?:\b|(?=\s)|$)/i,
    LGT  => qr/(?:^|\b)LI?GH?T\.?(?:\b|(?=\s)|$)/i,
    LGTS => qr/(?:^|\b)LI?GH?TS\.?(?:\b|(?=\s)|$)/i,
    LF   => qr/(?:^|\b)L(?:OA)?F\.?(?:\b|(?=\s)|$)/i,
    LCK  => qr/(?:^|\b)LO?CK(?!S)\.?(?:\b|(?=\s)|$)/i,
    LCKS => qr/(?:^|\b)LO?CKS\.?(?:\b|(?=\s)|$)/i,
    LDG  => qr/(?:^|\b)LO?DGE?\.?(?:\b|(?=\s)|$)/i,
    LOOP => qr/(?:^|\b)LOOPS?\.?(?:\b|(?=\s)|$)/i,
    MALL => qr/(?:^|\b)MALL\.?(?:\b|(?=\s)|$)/i,
    MNR  => qr/(?:^|\b)MA?NO?R(?!S)\.?(?:\b|(?=\s)|$)/i,
    MNRS => qr/(?:^|\b)MA?NO?RS\.?(?:\b|(?=\s)|$)/i,
    MDW  => qr/(?:^|\b)M(?:EA?)?DO?W(?!S)\.?(?:\b|(?=\s)|$)/i,
    MDWS => qr/(?:^|\b)M(?:EA?)?DO?WS\.?(?:\b|(?=\s)|$)/i,
    MEWS => qr/(?:^|\b)MEWS\.?(?:\b|(?=\s)|$)/i,
    ML   => qr/(?:^|\b)MI?L+(?!S)\.?(?:\b|(?=\s)|$)/i,
    MLS  => qr/(?:^|\b)MI?L+S\.?(?:\b|(?=\s)|$)/i,
    MSN  => qr/(?:^|\b)MI?S+(?:IO)?N\.?(?:\b|(?=\s)|$)/i,
    MTWY => qr/(?:^|\b)MO?T(?:OR)?WA?Y\.?(?:\b|(?=\s)|$)/i,
    MT   => qr/(?:^|\b)M(?:OU)?N?T(?![A-Z])\.?(?:\b|(?=\s)|$)/i,
    MTN  => qr/(?:^|\b)M(?:OU)?N?T(?:AI?|I)?N(?!S)\.?(?:\b|(?=\s)|$)/i,
    MTNS => qr/(?:^|\b)M(?:OU)?N?T(?:AI?|I)?NS\.?(?:\b|(?=\s)|$)/i,
    NCK  => qr/(?:^|\b)NE?CK\.?(?:\b|(?=\s)|$)/i,
    ORCH => qr/(?:^|\b)ORCH(?:A?RD)?\.?(?:\b|(?=\s)|$)/i,
    OVAL => qr/(?:^|\b)OVA?L\.?(?:\b|(?=\s)|$)/i,
    OPAS => qr/(?:^|\b)O(?:VER)?PAS+\.?(?:\b|(?=\s)|$)/i,
    PARK => qr/(?:^|\b)PA?R?KS?(?![A-Z])\.?(?:\b|(?=\s)|$)/i,
    PKWY => qr/(?:^|\b)PA?R?KW?A?YS?\.?(?:\b|(?=\s)|$)/i,
    PASS => qr/(?:^|\b)PASS(?![A-Z])\.?(?:\b|(?=\s)|$)/i,
    PSGE => qr/(?:^|\b)PA?S+A?GE\.?(?:\b|(?=\s)|$)/i,
    PATH => qr/(?:^|\b)PATHS?\.?(?:\b|(?=\s)|$)/i,
    PIKE => qr/(?:^|\b)PIKES?\.?(?:\b|(?=\s)|$)/i,
    PNE  => qr/(?:^|\b)PI?NE(?!S)\.?(?:\b|(?=\s)|$)/i,
    PNES => qr/(?:^|\b)PI?NES\.?(?:\b|(?=\s)|$)/i,
    PL   => qr/(?:^|\b)PL(?:ACE)?(?![A-Z])\.?(?:\b|(?=\s)|$)/i,
    PLN  => qr/(?:^|\b)PL(?:AI)?N(?![ES])\.?(?:\b|(?=\s)|$)/i,
    PLNS => qr/(?:^|\b)PL(?:AI)?NE?S\.?(?:\b|(?=\s)|$)/i,
    PLZ  => qr/(?:^|\b)PLA?ZA?\.?(?:\b|(?=\s)|$)/i,
    PT   => qr/(?:^|\b)P(?:OI)?N?T(?!S)\.?(?:\b|(?=\s)|$)/i,
    PTS  => qr/(?:^|\b)P(?:OI)?N?TS\.?(?:\b|(?=\s)|$)/i,
    PRT  => qr/(?:^|\b)PO?RT(?!S)\.?(?:\b|(?=\s)|$)/i,
    PRTS => qr/(?:^|\b)PO?RTS\.?(?:\b|(?=\s)|$)/i,
    PR   => qr/(?:^|\b)PR(?:(?:AI?)?R(?:IE)?|[^KT]?)?\.?(?:\b|(?=\s)|$)/i,
    RADL => qr/(?:^|\b)RAD(?:I[AE]?)?L?\.?(?:\b|(?=\s)|$)/i,
    RAMP => qr/(?:^|\b)RAMP\.?(?:\b|(?=\s)|$)/i,
    RNCH => qr/(?:^|\b)RA?NCH(?:E?S)?\.?(?:\b|(?=\s)|$)/i,
    RPD  => qr/(?:^|\b)RA?PI?D(?!S)\.?(?:\b|(?=\s)|$)/i,
    RPDS => qr/(?:^|\b)RA?PI?DS\.?(?:\b|(?=\s)|$)/i,
    RST  => qr/(?:^|\b)RE?ST\.?(?:\b|(?=\s)|$)/i,
    RDG  => qr/(?:^|\b)RI?DGE?(?!S)\.?(?:\b|(?=\s)|$)/i,
    RDGS => qr/(?:^|\b)RI?DGE?S\.?(?:\b|(?=\s)|$)/i,
    RIV  => qr/(?:^|\b)RI?VE?R?\.?(?:\b|(?=\s)|$)/i,
    RD   => qr/(?:^|\b)R(?:OA)?D(?![A-Z])\.?(?:\b|(?=\s)|$)(?:\b|$)/i,
    RDS  => qr/(?:^|\b)R(?:OA)?DS\.?(?:\b|(?=\s)|$)/i,
    RTE  => qr/(?:^|\b)R(?:OU)?TE\.?(?:\b|(?=\s)|$)/i,
    ROW  => qr/(?:^|\b)ROW\.?(?:\b|(?=\s)|$)/i,
    RUE  => qr/(?:^|\b)RUE\.?(?:\b|(?=\s)|$)/i,
    RUN  => qr/(?:^|\b)RUN\.?(?:\b|(?=\s)|$)/i,
    SHL  => qr/(?:^|\b)SH(?:OA)?L(?!S)\.?(?:\b|(?=\s)|$)/i,
    SHLS => qr/(?:^|\b)SH(?:OA)?LS\.?(?:\b|(?=\s)|$)/i,
    SHR  => qr/(?:^|\b)SH(?:OA?)?RE?(?!S)\.?(?:\b|(?=\s)|$)/i,
    SHRS => qr/(?:^|\b)SH(?:OA?)?RE?S\.?(?:\b|(?=\s)|$)/i,
    SKWY => qr/(?:^|\b)SKY?W?A?YS?\.?(?:\b|(?=\s)|$)/i,
    SPG  => qr/(?:^|\b)SP(?:RI?)?N?G(?!S)\.?(?:\b|(?=\s)|$)/i,
    SPGS => qr/(?:^|\b)SP(?:RI?)?N?GS\.?(?:\b|(?=\s)|$)/i,
    SPUR => qr/(?:^|\b)SPURS?\.?(?:\b|(?=\s)|$)/i,
    SQ   => qr/(?:^|\b)SQU?A?R?E?(?!S)\.?(?:\b|(?=\s)|$)/i,
    SQS  => qr/(?:^|\b)SQU?A?R?E?S\.?(?:\b|(?=\s)|$)/i,
    STA  => qr/(?:^|\b)ST(?:N|AT?(?:IO)?N?)\.?(?:\b|(?=\s)|$)/i,
    STRA => qr/(?:^|\b)STR(?:VN|AV?E?N?U?E?)\.?(?:\b|(?=\s)|$)/i,
    STRM => qr/(?:^|\b)STRE?A?ME?\.?(?:\b|(?=\s)|$)/i,
    ST   => qr/(?:^|\b)ST(?:\.|R(?:EE)?T?\.?)?(?:\b|(?=\s)|$)/i,
    STS  => qr/(?:^|\b)STR?E*T?S\.?(?:\b|(?=\s)|$)/i,
    SMT  => qr/(?:^|\b)SU?M+I?T+\.?(?:\b|(?=\s)|$)/i,
    TER  => qr/(?:^|\b)TER(?:R(?:ACE)?)?\.?(?:\b|(?=\s)|$)/i,
    TRWY => qr/(?:^|\b)TH?R(?:OUGH)?WA?Y\.?(?:\b|(?=\s)|$)/i,
    TRCE => qr/(?:^|\b)TRA?CES?\.?(?:\b|(?=\s)|$)/i,
    TRAK => qr/(?:^|\b)TRA?C?KS?\.?(?:\b|(?=\s)|$)/i,
    TRFY => qr/(?:^|\b)TRA?F(?:FICWA)?Y\.?(?:\b|(?=\s)|$)/i,
    TRL  => qr/(?:^|\b)TR(?:(?:AI)?LS?\.?|\.?)(?:\b|(?=\s)|$)/i,
    TUNL => qr/(?:^|\b)TUNN?E?LS?\.?(?:\b|(?=\s)|$)/i,
    TPKE => qr/(?:^|\b)T(?:U?RN?)?PI?KE?\.?(?:\b|(?=\s)|$)/i,
    UPAS => qr/(?:^|\b)U(?:NDER)?PA?SS?\.?(?:\b|(?=\s)|$)/i,
    UN   => qr/(?:^|\b)U(?:NIO)?N(?![IS])\.?(?:\b|(?=\s)|$)/i,
    UNS  => qr/(?:^|\b)U(?:NIO)?NS\.?(?:\b|(?=\s)|$)/i,
    VLY  => qr/(?:^|\b)VA?LL?E?Y(?!S)\.?(?:\b|(?=\s)|$)/i,
    VLYS => qr/(?:^|\b)VA?LL?E?YS\.?(?:\b|(?=\s)|$)/i,
    VIA  => qr/(?:^|\b)V(?:IA)?(?:DU?CT)?\.?(?:\b|(?=\s)|$)/i,
    VW   => qr/(?:^|\b)V(?:IE)?W(?!S)\.?(?:\b|(?=\s)|$)/i,
    VWS  => qr/(?:^|\b)V(?:IE)?WS\.?(?:\b|(?=\s)|$)/i,
    VLG  => qr/(?:^|\b)V(?:LG|ILL(?:I?AGE?)?)[^ES]?\.?(?:\b|(?=\s)|$)/i,
    VLGS => qr/(?:^|\b)V(?:LG|ILL(?:I?AGE?)?)[^E]?S\.?(?:\b|(?=\s)|$)/i,
    VL   => qr/(?:^|\b)V(?:L[^GLY]*|I?LL?E)\.?(?:\b|(?=\s)|$)/i,
    VIS  => qr/(?:^|\b)VI?S(?:TA?)?\.?(?:\b|(?=\s)|$)/i,
    WALK => qr/(?:^|\b)WALKS?\.?(?:\b|(?=\s)|$)/i,
    WALL => qr/(?:^|\b)WALL\.?(?:\b|(?=\s)|$)/i,
    WAY  => qr/(?:^|\b)WA?Y(?!S)\.?(?:\b|(?=\s)|$)/i,
    WAYS => qr/(?:^|\b)WA?YS\.?(?:\b|(?=\s)|$)/i,
    WL   => qr/(?:^|\b)WE?LL?(?!S)\.?(?:\b|(?=\s)|$)/i,
    WLS  => qr/(?:^|\b)WE?LL?S\.?(?:\b|(?=\s)|$)/i,
);

# Defined in B - "Two-Letter State and Possession Abbreviations"
my %state_province_abbrev = (
        AL =>  qr/(?:^|\b)AL(?:A(?:\.|BAMA)?)?\.?(?:\b|$)/i,
        AK =>  qr/(?:^|\b)A(?:K|LAS(?:KA?)?)\.?(?:\b|$)/i,
        AS =>  qr/(?:^|\b)
            A(?:M(?:ER(?:ICAN)?)?)?\.?
            \s*
            S(?:AM(?:OA)?)?\.?
            |A\.?\s*S\.?
            (?:\b|$)/ix,
        AZ =>  qr/(?:^|\b)A(?:Z\.?|RI(?:\.|Z(?:\.|ONA)?)?)(?:\b|$)/i,
        AR =>  qr/(?:^|\b)AR(?:\.|K(?:\.|ANSAS))(?:\b|$)/i,
        CA =>  qr/(?:^|\b)CA(?:\.|L(?:\.|IF(?:\.|ORNIA)?))(?:\b|$)/i,
        CO =>  qr/(?:^|\b)CO(?:\.|L(?:\.|O(?:\.|RADO)?)?)(?:\b|$)/i,
        CT =>  qr/(?:^|\b)C(?:T\.?|ONN(?:\.|ECTICUT)?)(?:\b|$)/i,
        DE =>  qr/(?:^|\b)DE(?:\.|L(?:\.|EWARE)?)(?:\b|$)/i,
        DC =>  qr/(?:^|\b)
            D(?:\.|IST(?:\.|RICT)?)?
            \s*
            (?:O[.F]?)?
            \s*
            C(?:\.|OL(?:\.|UM(?:\.|BIA)?)?)?
            (?:\b|$)/ix,
        FM =>  qr/(?:^|\b)
            F(?:\.|ED(?:\.|ERATED)?)?
            \s*
            (?:S(?:T(?:ATES?)?)?\.?)?
            \s*
            (?:O[.F]?)?
            \s*
            M(?:IC(?:RO(?:NESIA)?)?)?\.?
            (?:\b|$)/ix,
        FL =>  qr/(?:^|\b)F(?:L(?:ORID?)?A?)\.?(?:\b|$)/i,
        GA =>  qr/(?:^|\b)G(?:EORGI)?A\.?(?:\b|$)/i,
        GU =>  qr/(?:^|\b)GU(?:\.|AM)?(?:\b|$)/i,
        HI =>  qr/(?:^|\b)H(?:AWAI)?I\.?(?:\b|$)/i,
        ID =>  qr/(?:^|\b)ID(?:\.|AHO)?(?:\b|$)/i,
        IL =>  qr/(?:^|\b)IL(?:\.|L(?:\.|INOIS)?)?(?:\b|$)/i,
        IN =>  qr/(?:^|\b)IN(?:D(?:\.|IANA)?)?\.?(?:\b|$)/i,
        IA =>  qr/(?:^|\b)I(?:OW)?A\.?(?:\b|$)/i,
        KS =>  qr/(?:^|\b)K(?:AN)?(?:SA)?(?:S)?\.?(?:\b|$)/i,
        KY =>  qr/(?:^|\b)K(?:EN)?(?:TUCK)?(?:Y)?\.?(?:\b|$)/i,
        LA =>  qr/(?:^|\b)L(?:OUIS)?(?:IAN)?A?\.?(?:\b|$)/i,
        ME =>  qr/(?:^|\b)M(?:AIN)?E\.?(?:\b|$)/i,
        MH =>  qr/(?:^|\b)(?:MARSH(?:ALL?)?\.?\s*IS(?:LANDS?)?|MH)\.?(?:\b|$)/i,
        MD =>  qr/(?:^|\b)M(?:ARYLA?N)?D\.?(?:\b|$)/i,
        MA =>  qr/(?:^|\b)MA(?:SS(?:\.|ACHUSETTS)?)?\.?(?:\b|$)/i,
        MI =>  qr/(?:^|\b)MI(?:CH(?:IGAN)?)?\.?(?:\b|$)/i,
        MN =>  qr/(?:^|\b)M(?:IN)?N(?:ESOTA)?\.?(?:\b|$)/i,
        MS =>  qr/(?:^|\b)M(?:IS)?S(?:ISSIPPI)?\.?(?:\b|$)/i,
        MO =>  qr/(?:^|\b)M(?:ISS)?O(?:URI)?\.?(?:\b|$)/i,
        MT =>  qr/(?:^|\b)M(?:ON)?T(?:ANA)?\.?(?:\b|$)/i,
        NE =>  qr/(?:^|\b)NEB?(?:R(?:ASKA)?)?\.?(?:\b|$)/i,
        NV =>  qr/(?:^|\b)NE?V(?:ADA)?\.?(?:\b|$)/i,
        NH =>  qr/(?:^|\b)N(?:EW)?\.?\s*H(?:AMPS?(?:HIRE)?)?\.?(?:\b|$)/i,
        NJ =>  qr/(?:^|\b)N(?:EW)?\.?\s*J(?:ERS?(?:EY)?)?\.?(?:\b|$)/i,
        NM =>  qr/(?:^|\b)N(?:EW)?\.?\s*M(?:EX(?:ICO)?)?\.?(?:\b|$)/i,
        NY =>  qr/(?:^|\b)N(?:EW)?\.?\s*Y(?:ORK)?\.?(?:\b|$)/i,
        NC =>  qr/(?:^|\b)N(?:OR)?(?:TH)?\.?\s*C(?:AR(?:OLINA?)?)?\.?(?:\b|$)/i,
        ND =>  qr/(?:^|\b)N(?:OR)?(?:TH)?\.?\s*D(?:AK(?:OTA)?)?\.?(?:\b|$)/i,
        MP =>  qr/(?:^|\b)
            (?:N(?:OR)?(?:TH(?:ERN)?)?\.?
                \s*
                MARI?(?:ANA)?\.?
                \s*
                I(?:S(?:LANDS?)?)?\.?
            |MP\.?)
            (?:\b|$)/ix,
        OH =>  qr/(?:^|\b)OH(?:IO)?\.?(?:\b|$)/i,
        OK =>  qr/(?:^|\b)OK(?:LA(?:\.|HOMA)?)?\.?(?:\b|$)/i,
        OR =>  qr/(?:^|\b)OR(?:E(?:G(?:ON)?)?)?\.?(?:\b|$)/i,
        PA =>  qr/(?:^|\b)P(?:ENNS?(?:YLVANIA)?|A)\.?(?:\b|$)/i,
        PW =>  qr/(?:^|\b)P(?:AL(?:AU)?|W)\.?(?:\b|$)/i,
        PR =>  qr/(?:^|\b)PU?(?:ER(?:T(?:O)?)?)?\.?\s*RI?(?:CO)?\.?(?:\b|$)/i,
        RI =>  qr/(?:^|\b)R(?:H(?:ODE)?)?\.?\s*I(?:S(?:LAND)?)?\.?(?:\b|$)/i,
        SC =>  qr/(?:^|\b)S(?:OU)?(?:TH)?\.?\s*C(?:AR(?:OLINA?)?)?\.?(?:\b|$)/i,
        SD =>  qr/(?:^|\b)S(?:OU)?(?:TH)?\.?\s*D(?:AK(?:OTA)?)?\.?(?:\b|$)/i,
        TN =>  qr/(?:^|\b)TE?N(?:N(?:ESSEE)?)?\.?(?:\b|$)/i,
        TX =>  qr/(?:^|\b)TE?X(?:AS)?\.?(?:\b|$)/i,
        UT =>  qr/(?:^|\b)UT(?:AH)?\.?(?:\b|$)/i, 
        VT =>  qr/(?:^|\b)V(?:ER(?:MO?N?)?T?|T)\.?(?:\b|$)/i,
        VI =>  qr/(?:^|\b)V(?:IRGIN)?\.?\s*I(?:S(?:LANDS?)?)?\.?(?:\b|$)/i,
        VA =>  qr/(?:^|\b)V(?:IR(?:GINIA)?|A)\.?(?:\b|$)/i,
        WA =>  qr/(?:^|\b)WA(?:SH(?:INGTON)?)?\.?(?:\b|$)/i,
        WV =>  qr/(?:^|\b)W(?:EST)?\.?\s*V(?:IR(?:G(?:INIA)?)?|A)?\.?(?:\b|$)/i,
        WI =>  qr/(?:^|\b)WI(?:S(?:CONS?(?:IN)?)?)?\.?(?:\b|$)/i,
        WY =>  qr/(?:^|\b)WYO?(?:MING)?\.?(?:\b|$)/i,
        AE =>  qr/(?:^|\b)
            A(?:RM(?:(?:E|[\'\`])?D)?)?\.?
            \s*
            (?:F(?:OR(?:CES?)?)?\.?)?
            \s*
            (?:AF(?:R(?:ICA)?)?|
                CA(?:N(?:ADA)?)?|
                E(?:U(?:R(?:OPE)?)?)?|
                M(?:ID(?:DLE)?)?\.?\s*E(?:A?ST)?)\.?
            (?:\b|$)/ix,
        AA =>  qr/(?:^|\b)
            A(?:RM(?:(?:E|[\'\`])?D)?)?\.?
            \s*
            (?:F(?:OR(?:CES?)?)?\.?)?
            \s
            *A(?:M(?:ER(?:ICA)?)?)?\.?
            (?:\b|$)/ix,
        AP =>  qr/(?:^|\b)
            A(?:RM(?:(?:E|[\'\`])?D)?)?\.?
            \s*
            (?:F(?:OR(?:CES?)?)?\.?)?
            \s* P(?:\.|AC(?:\.|IFIC)?)?\.?
            (?:\b|$)/ix,
    );

sub standardize {
    my ($self, $address) = @_;

    my $newaddr = $address->clone;
    my $results = Geo::Address::Mail::Standardizer::Results->new(
        standardized_address => $newaddr );

    $self->_uppercase($newaddr, $results);
    $self->_remove_punctuation($newaddr, $results);
    $self->_replace_designators($newaddr, $results);
    $self->_replace_state_abbreviations($newaddr, $results);

    return $results;
}

# Make everything uppercase 212
sub _uppercase {
    my ($self, $addr, $results) = @_;

    # We won't mark anything as changed here because I personally don't think
    # the user cares if uppercasing is the only change.
    my @fields = qw(company name street street2 city state state country);
    foreach my $field (@fields) {
        $addr->$field(uc($addr->$field)) if defined($addr->$field);
    }
}

# Remove punctuation, none is really needed.  222
sub _remove_punctuation {
    my ($self, $addr, $results) = @_;

    my @fields = qw(company name street street2 city state state country);
    foreach my $field (@fields) {
        my $val = $addr->$field;
        next unless defined($val);

        if($val ne $addr->$field) {
            $results->set_changed($field, $val);
            $addr->$field($val);
        }
    }
}

# Replace Secondary Address Unit Designators, 213
# Uses Designators from 213.1, Appendix C1, and Appendix C2
sub _replace_designators {
    my ($self, $addr, $results) = @_;

    my @fields = qw(street street2);
    foreach my $field (@fields) {
        my $val = $addr->$field;
        next unless defined($val);

        foreach my $rd ( sort { $a cmp $b } keys(%range_designators) ) {
            if ( $val =~ $range_designators{$rd} ) {
                $val =~ s/$range_designators{$rd}/$rd/gi;
                $results->set_changed( $field, $val );
                $addr->$field($val);
            }
        }

        foreach my $d ( sort { $a cmp $b } keys(%designators) ) {
            if ( $val =~ $designators{$d} ) {
                $val =~ s/$designators{$d}/$d/gi;
                $results->set_changed( $field, $val );
                $addr->$field($val);
            }
        }

        foreach my $sd ( sort { $a cmp $b } keys(%street_suffix_abbrev) ) {
            if ( $val =~ $street_suffix_abbrev{$sd} ) {
                $val =~ s/$street_suffix_abbrev{$sd}/$sd/gi;
                $results->set_changed($field, $val);
                $addr->$field($val);
            }
        }
    }
}

# Replace State/Province/Possession Abbreviations
# Uses Abbreviations from Appendix B
sub _replace_state_abbreviations {
    my ($self, $addr, $results) = @_;

    my @fields = qw(state);
    foreach my $field (@fields) {
        my $val = $addr->$field;
        next unless defined($val);

        foreach my $st (sort{ $a cmp $b }keys(%state_province_abbrev)) {
            if($val =~ $state_province_abbrev{$st}) {
                $val =~ s/$state_province_abbrev{$st}/$st/gi;
                $results->set_changed($field, $val);
                $addr->$field($val);
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Geo::Address::Mail::Standardizer::USPS - Offline implementation of USPS Postal Addressing Standards

=head1 SYNOPSIS

This module provides an offline implementation of the USPS Publication 28 - 
Postal Addressing Standards as defined by
L<http://pe.usps.com/text/pub28/welcome.htm>.

    my $std = Geo::Address::Mail::Standardizer::USPS->new;

    my $address = Geo::Address::Mail::US->new(
        name => 'Test Testerson',
        street => '123 Test Street',
        street2 => 'Apartment #2',
        city => 'Testville',
        state => 'TN',
        postal_code => '12345'
    );

    my $res = $std->standardize($address);
    my $corr = $res->standardized_address;

=head1 WARNING

This module is not a complete implementation of USPS Publication 28.  It
intends to be, but that will probably take a while.  In the meantime it
may be useful for testing or for pseudo-standardizaton.

=head1 USPS Postal Address Standards Implemented

This module currently handles the following sections from Publication 28:

=over 5

=item I<212 Format>

L<http://pe.usps.com/text/pub28/pub28c2_002.htm>

=item I<213.1 Common Designators>

L<http://pe.usps.com/text/pub28/pub28c2_003.htm>

Also, Appendix C1

L<http://pe.usps.com/text/pub28/pub28apc_002.html>

Also, Appendix C2

L<http://pe.usps.com/text/pub28/pub28apc_003.htm#ep538629>

=item I<222 Punctuation>

Punctuation is removed from all fields except C<postal_code>.  Note that
this isn't really kosher when using address ranges...

L<http://pe.usps.com/text/pub28/pub28c2_007.htm>

=back

=item I<211 Standardized Delivery Address Line and Last Line>

The C<state> field values are translated to their abbreviated form, as 
given in Appendix B.

L<http://pe.usps.com/text/pub28/pub28apb.htm>

=back

=item I<225.1 Overseas Locations>

Overseas military addresses translate the C<state> field as given in 
Appendix B.

L<http://pe.usps.com/text/pub28/pub28c2_010.htm>

=back

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Albert Croft

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

