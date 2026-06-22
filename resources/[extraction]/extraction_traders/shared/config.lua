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
