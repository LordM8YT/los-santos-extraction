ExtractionTraders = ExtractionTraders or {}

ExtractionTraders.Shops = {
    quartermaster = {
        label = 'Quartermaster',
        description = 'Basic weapons, ammunition and survival supplies for the next raid.',
        items = {
            {
                item = 'pistol',
                label = 'Pistol',
                price = 650,
                quantity = 1,
                limit = 1,
                category = 'Weapon',
                description = 'Reliable sidearm. Lost on death if deployed.',
            },
            {
                item = 'pistol_ammo',
                label = '9mm Ammo Pack',
                price = 120,
                quantity = 24,
                limit = 240,
                category = 'Ammo',
                description = 'Twenty-four rounds for the starter pistol.',
            },
            {
                item = 'meds',
                label = 'Medical Supplies',
                price = 320,
                quantity = 1,
                limit = 10,
                category = 'Medical',
                description = 'Basic field supplies. Also progresses early medical tasks.',
            },
            {
                item = 'smg_ammo',
                label = 'SMG Ammo Pack',
                price = 180,
                quantity = 30,
                limit = 180,
                category = 'Ammo',
                description = 'Thirty rounds for extracted SMGs.',
            },
            {
                item = 'shotgun_ammo',
                label = 'Shotgun Shell Box',
                price = 160,
                quantity = 12,
                limit = 72,
                category = 'Ammo',
                description = 'Twelve shells for extracted shotguns.',
            },
            {
                item = 'rifle_ammo',
                label = 'Rifle Ammo Pack',
                price = 240,
                quantity = 30,
                limit = 180,
                category = 'Ammo',
                description = 'Thirty rounds for extracted rifles.',
            },
        },
    },
}

function ExtractionTraders.GetShop(shopId)
    return ExtractionTraders.Shops[shopId or 'quartermaster']
end

function ExtractionTraders.GetShopItems(shopId)
    local shop = ExtractionTraders.GetShop(shopId)
    return shop and shop.items or {}
end
