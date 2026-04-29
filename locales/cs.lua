-- Add translations by MC
local Translations = {
    headers = {
        ['bsm'] = 'Boss Menu - ',
    },
    body = {
        ['manage'] = 'ZamÄ›stnanci',
        ['managed'] = 'List zamÄ›stnancÅ¯',
        ['hire'] = 'Nabrat civilistu',
        ['hired'] = 'Nabrat nejbliÅ¾Å¡Ã­ho civilistu',
        ['storage'] = 'Trezor',
        ['storaged'] = 'OtevÅ™Ã­t trezor',
        ['outfits'] = 'ObleÄenÃ­',
        ['outfitsd'] = 'UloÅ¾enÃ© obleÄenÃ­',
        ['money'] = 'Finance',
        ['moneyd'] = 'Zkontrolovat stav ÃºÄtu',
        ['mempl'] = 'Spravovat zamÄ›stnance - ',
        ['mngpl'] = 'Spravovat ',
        ['grade'] = 'Hodnost: ',
        ['fireemp'] = 'Propustit zamÄ›stnance',
        ['hireemp'] = 'Nabrat civilistu - ',
        ['cid'] = 'ID hrÃ¡Äe: ',
        ['balance'] = 'Stav ÃºÄtu: $',
        ['deposit'] = 'VloÅ¾it penÃ­ze',
        ['depositd'] = 'VloÅ¾it penÃ­ze na ÃºÄet',
        ['withdraw'] = 'Vybrat penÃ­ze',
        ['withdrawd'] = 'Vybrat penize z kasy',
        ['depositm'] = 'VloÅ¾it penÃ­ze <br> ZÅ¯statek financÃ­: $',
        ['withdrawm'] = 'Vybrat penÃ­ze <br> ZÅ¯statek financÃ­: $',
        ['submit'] = 'Potrvdit',
        ['amount'] = 'Hodnota',
        ['return'] = 'ZpÄ›t',
        ['exit'] = 'OdejÃ­t',
    },
    drawtext = {
        ['label'] = '[E] Open Job Management',
    },
    target = {
        ['label'] = 'VedenÃ­ Frakce',
    },
    headersgang = {
        ['bsm'] = 'VedenÃ­ gangÅ¯  - ',
    },
    bodygang = {
        ['manage'] = 'Spravovat Äleny gangu',
        ['managed'] = 'PÅ™ijÃ­mÃ¡nÃ­ nebo propouÅ¡tÄ›nÃ­ ÄlenÅ¯ gangu',
        ['hire'] = 'NÃ¡bor ÄlenÅ¯',
        ['hired'] = 'Najmout Äleny Gangu',
        ['storage'] = 'PÅ™Ã­stup k ÃºloÅ¾iÅ¡ti',
        ['storaged'] = 'OtevÅ™Ã­t Gang UloÅ¾iÅ¡tÄ›',
        ['outfits'] = 'Outfity',
        ['outfitsd'] = 'VÃ½mÄ›na obleÄenÃ­',
        ['money'] = 'SprÃ¡va penÄ›z',
        ['moneyd'] = 'Kontrola zÅ¯statku Gangu',
        ['mempl'] = 'Spravovat Gang Äleny - ',
        ['mngpl'] = 'Spravovat ',
        ['grade'] = 'Hodnost: ',
        ['fireemp'] = 'Propustit Älena',
        ['hireemp'] = 'Nabrat civilistu - ',
        ['cid'] = 'ID hrÃ¡Äe: ',
        ['balance'] = 'Stav ÃºÄtu: $',
        ['deposit'] = 'VloÅ¾it penÃ­ze',
        ['depositd'] = 'VloÅ¾it penÃ­ze na ÃºÄet',
        ['withdraw'] = 'Vybrat penÃ­ze',
        ['withdrawd'] = 'Vybrat penize z kasy',
        ['depositm'] = 'VloÅ¾it penÃ­ze <br> ZÅ¯statek financÃ­: $',
        ['withdrawm'] = 'Vybrat penÃ­ze <br> ZÅ¯statek financÃ­: $',
        ['submit'] = 'Confirm',
        ['amount'] = 'Potrvdit',
        ['return'] = 'ZpÄ›t',
        ['exit'] = 'OdejÃ­t',
    },
    drawtextgang = {
        ['label'] = '[E] Open Gang Management',
    },
    targetgang = {
        ['label'] = 'Gang Menu',
    }
}

if GetConvar('qb_locale', 'en') == 'cs' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
