%lang starknet

// Payer Account
const PAYER_ADDRESS = 36491145959961396332960543214365843200009024482240237550208495073623621278;
const PAYER_PUBLIC_KEY = 1896931168835482560420262980474744441166341269590392383470938365630861229684;
const PAYER_PRIVATE_KEY = 152101197396937309817497795890514377031;

// User Paid Account
const USER_ADDRESS = 47231116564321770019784631178929675869780784734392999037444150086429730360;
const USER_PUBLIC_KEY = 2476378521693838184788810103137140343255179376116014061409080863620365650670;
const USER_PRIVATE_KEY = 249170180730317735512592466975812541085;

// Not Payer Account
const NOT_PAYER_ADDRESS = 1225750184250042898779440531961309799279893904540613768264309229659145628129;
const NOT_PAYER_PUBLIC_KEY = 1604292307896102639395639722934545434726042597627861716852742760766626387683;
const NOT_PAYER_PRIVATE_KEY = 301018475396898247447065413378605421205;

// Tx Info
const RECEIVER_ADDRESS = 3298816400457082843483515869972152809139381632851969121918527563290062300898;
const AMOUNT = 1000;

// ERC20 contract
const ETH_TOKEN_ADDRESS = 2302970397164951055129193732789663895909419831587348151965008190273601354621;
const TRANSFER_SELECTOR = 232670485425082704932579856502088130646006032362877466777181098476241604910;
const ERC20_NAME = 'ETH';
const ERC20_SYMBOL = 'ETH';
const DECIMALS = 18;
const INITIAL_SUPPLY = 1000000000000000000000;
const RECIPIENT = PAYER_ADDRESS;