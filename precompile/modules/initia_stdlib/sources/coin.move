/// TODO - make is_module_account or some blacklist from freeze.
module initia_std::coin {
    use std::bcs;
    use std::from_bcs;
    use std::option::Option;
    use std::string::{Self, String};
    use std::vector;

    use initia_std::event;
    use initia_std::primary_fungible_store;
    use initia_std::fungible_asset::{Self, MintRef, BurnRef, TransferRef, FungibleAsset, Metadata};
    use initia_std::object::{Self, Object, ExtendRef};

    struct ManagingRefs has key {
        mint_ref: MintRef,
        burn_ref: BurnRef,
        transfer_ref: TransferRef,
    }

    /// Only fungible asset metadata owner can make changes.
    const ERR_NOT_OWNER: u64 = 1;

    /// ManagingRefs is not found.
    const ERR_MANAGING_REFS_NOT_FOUND: u64 = 2;

    #[event]
    struct CoinCreatedEvent has drop, store {
        metadata_addr: address,
    }

    struct MintCapability has drop, store {
        metadata: Object<Metadata>,
    }
    struct BurnCapability has drop, store {
        metadata: Object<Metadata>,
    }
    struct FreezeCapability has drop, store {
        metadata: Object<Metadata>,
    }

    //
    // public interfaces
    //

    public fun initialize (
        creator: &signer,
        maximum_supply: Option<u128>,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
    ): (MintCapability, BurnCapability, FreezeCapability) {
        let (mint_cap, burn_cap, freeze_cap, _) = initialize_and_generate_extend_ref(
            creator,
            maximum_supply,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri,
        );

        (mint_cap, burn_cap, freeze_cap)
    }

    public fun initialize_and_generate_extend_ref (
        creator: &signer,
        maximum_supply: Option<u128>,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
    ): (MintCapability, BurnCapability, FreezeCapability, ExtendRef) {
        // create object for fungible asset metadata
        let constructor_ref = &object::create_named_object(creator, *string::bytes(&symbol), false);

        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            maximum_supply,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri,
        );

        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);

        let object_signer = object::generate_signer(constructor_ref);
        move_to(&object_signer, ManagingRefs {
            mint_ref,
            burn_ref,
            transfer_ref,
        });

        let metadata_addr = object::address_from_constructor_ref(constructor_ref);
        event::emit(CoinCreatedEvent {
            metadata_addr,
        });

        let metadata = object::object_from_constructor_ref<Metadata>(constructor_ref);
        (MintCapability { metadata }, BurnCapability { metadata }, FreezeCapability { metadata }, object::generate_extend_ref(constructor_ref))
    }

    public fun withdraw (
        account: &signer,
        metadata: Object<Metadata>,
        amount: u64,
    ): FungibleAsset {
        primary_fungible_store::withdraw(account, metadata, amount)
    }

    public fun deposit (
        account_addr: address,
        fa: FungibleAsset,
    ) {
        primary_fungible_store::deposit(account_addr, fa)
    }

    public entry fun transfer (
        sender: &signer,
        recipient: address,
        metadata: Object<Metadata>,
        amount: u64,
    ) {
        primary_fungible_store::transfer(sender, metadata, recipient, amount)
    }

    //
    // Admin operations
    //

    /// Mint FAs as the owner of metadat object.
    public fun mint(
        mint_cap: &MintCapability,
        amount: u64,
    ): FungibleAsset acquires ManagingRefs {
        let metadata = mint_cap.metadata;
        let metadata_addr = object::object_address(metadata);

        assert!(exists<ManagingRefs>(metadata_addr), ERR_MANAGING_REFS_NOT_FOUND);
        let refs = borrow_global<ManagingRefs>(metadata_addr);

        fungible_asset::mint(&refs.mint_ref, amount)
    }

    /// Mint FAs as the owner of metadat object to the primary fungible store of the given recipient.
    public fun mint_to(
        mint_cap: &MintCapability,
        recipient: address,
        amount: u64,
    ) acquires ManagingRefs {
        let metadata = mint_cap.metadata;
        let metadata_addr = object::object_address(metadata);

        assert!(exists<ManagingRefs>(metadata_addr), ERR_MANAGING_REFS_NOT_FOUND);
        let refs = borrow_global<ManagingRefs>(metadata_addr);

        primary_fungible_store::mint(&refs.mint_ref, recipient, amount)
    }

    /// Burn FAs as the owner of metadat object.
    public fun burn(
        burn_cap: &BurnCapability,
        fa: FungibleAsset,
    ) acquires ManagingRefs {
        let metadata = burn_cap.metadata;
        let metadata_addr = object::object_address(metadata);

        assert!(exists<ManagingRefs>(metadata_addr), ERR_MANAGING_REFS_NOT_FOUND);
        let refs = borrow_global<ManagingRefs>(metadata_addr);

        fungible_asset::burn(&refs.burn_ref, fa)
    }

    /// Freeze the primary store of an account.
    public fun freeze_coin_store(
        freeze_cap: &FreezeCapability,
        account_addr: address,
    ) acquires ManagingRefs {
        let metadata = freeze_cap.metadata;
        let metadata_addr = object::object_address(metadata);

        assert!(exists<ManagingRefs>(metadata_addr), ERR_MANAGING_REFS_NOT_FOUND);
        let refs = borrow_global<ManagingRefs>(metadata_addr);

        primary_fungible_store::set_frozen_flag(&refs.transfer_ref, account_addr, true)
    }

    /// Unfreeze the primary store of an account.
    public fun unfreeze_coin_store(
        freeze_cap: &FreezeCapability,
        account_addr: address,
    ) acquires ManagingRefs {
        let metadata = freeze_cap.metadata;
        let metadata_addr = object::object_address(metadata);

        assert!(exists<ManagingRefs>(metadata_addr), ERR_MANAGING_REFS_NOT_FOUND);
        let refs = borrow_global<ManagingRefs>(metadata_addr);

        primary_fungible_store::set_frozen_flag(&refs.transfer_ref, account_addr, false)
    }

    //
    // Query interfaces
    //

    #[view]
    public fun balance(account: address, metadata: Object<Metadata>): u64 {
        primary_fungible_store::balance(account, metadata)
    }

    #[view]
    public fun is_frozen(account: address, metadata: Object<Metadata>): bool {
        primary_fungible_store::is_frozen(account, metadata)
    }

    #[view]
    public fun balances(
        account: address,
        start_after: Option<address>,
        limit: u8,
    ): (vector<Object<Metadata>>, vector<u64>) {
        primary_fungible_store::balances(account, start_after, limit)
    }

    #[view]
    /// Get the current supply from the `metadata` object.
    public fun supply(metadata: Object<Metadata>): Option<u128> {
        fungible_asset::supply(metadata)
    }

    #[view]
    /// Get the maximum supply from the `metadata` object.
    public fun maximum(metadata: Object<Metadata>): Option<u128> {
        fungible_asset::maximum(metadata)
    }

    #[view]
    /// Get the name of the fungible asset from the `metadata` object.
    public fun name(metadata: Object<Metadata>): String {
        fungible_asset::name(metadata)
    }

    #[view]
    /// Get the symbol of the fungible asset from the `metadata` object.
    public fun symbol(metadata: Object<Metadata>): String {
        fungible_asset::symbol(metadata)
    }

    #[view]
    /// Get the decimals from the `metadata` object.
    public fun decimals(metadata: Object<Metadata>): u8 {
        fungible_asset::decimals(metadata)
    }

    #[view]
    public fun metadata_address(creator: address, symbol: String): address {
        object::create_object_address(creator, *string::bytes(&symbol))
    }

    #[view]
    public fun metadata(creator: address, symbol: String): Object<Metadata> {
        object::address_to_object<Metadata>(metadata_address(creator, symbol))
    }

    #[view]
    public fun is_coin_initialized(metadata: Object<Metadata>): bool {
        let metadata_addr = object::object_address(metadata);
        exists<ManagingRefs>(metadata_addr)
    }

    #[view]
    public fun metadata_to_denom(metadata: Object<Metadata>): String {
        let metadata_addr = object::object_address(metadata);
        let symbol = symbol(metadata);
        let std_metadata_addr = metadata_address(@initia_std, symbol);

        if (std_metadata_addr == metadata_addr) {
            return symbol
        };

        let denom = string::utf8(b"move/");
        let addr_bytes = bcs::to_bytes(&metadata_addr);
        let addr_string = string::utf8(hash_to_utf8(addr_bytes));
        string::append(&mut denom, addr_string);
        return denom
    }

    #[view]
    public fun denom_to_metadata(denom: String): Object<Metadata> {
        let addr = if (string::length(&denom) > 5 && &b"move/" == string::bytes(&string::sub_string(&denom, 0, 5))) {
            let len = string::length(&denom);
            let utf8 = string::bytes(&string::sub_string(&denom, 5, len));
            std::debug::print(&utf8_to_hash(*utf8));
            from_bcs::to_address(utf8_to_hash(*utf8))
        } else {
            metadata_address(@initia_std, denom)
        };

        object::address_to_object(addr)
    }

    fun hash_to_utf8(hash: vector<u8>): vector<u8> {
        let vec: vector<u8> = vector[];
        let len = vector::length(&hash);
        let index = 0;
        while(index < len) {
            let val = *vector::borrow(&hash, index);
            let h = val / 0x10;
            let l = val % 0x10;
            vector::push_back(&mut vec, hex_num_to_utf8(h));
            vector::push_back(&mut vec, hex_num_to_utf8(l));
            index = index + 1;
        };

        vec
    }

    fun utf8_to_hash(utf8: vector<u8>): vector<u8> {
        let vec: vector<u8> = vector[];
        let len = vector::length(&utf8);
        let index = len - 1;
        while(index > 0) {
            let l = utf8_to_hex_num(*vector::borrow(&utf8, index));
            let h = if (index == 0) {
                0
            } else {
                utf8_to_hex_num(*vector::borrow(&utf8, index - 1))
            };

            vector::push_back(&mut vec, l + (h << 4));
            if (index == 1) break;
            index = index - 2
        };
        vector::reverse(&mut vec);
        vec
    }

    fun hex_num_to_utf8(num: u8): u8 {
        if (num < 10) {
            0x30 + num
        } else {
            0x57 + num
        }
    }

    fun utf8_to_hex_num(num: u8): u8 {
        if (num < 0x3a) {
            num - 0x30
        } else {
            num - 0x57
        }
    }

    #[test_only]
    fun initialized_coin(
        account: &signer,
        symbol: String,
    ): (BurnCapability, FreezeCapability, MintCapability) {
        let (mint_cap, burn_cap, freeze_cap, _) = initialize_and_generate_extend_ref (
            account,
            std::option::none(),
            string::utf8(b""),
            symbol,
            6,
            string::utf8(b""),
            string::utf8(b""),
        );

        return (burn_cap, freeze_cap, mint_cap)
    }

    #[test(chain = @0x1, not_chain = @0x2)]
    fun test_denom_metadata_convert(
        chain: signer,
        not_chain: signer,
    ) {
        initia_std::primary_fungible_store::init_module_for_test(&chain);
        initialized_coin(&chain, string::utf8(b"INIT"));
        initialized_coin(&not_chain, string::utf8(b"INIT"));
        let metadata = metadata(std::signer::address_of(&chain), string::utf8(b"INIT"));
        let metadata_ = metadata(std::signer::address_of(&not_chain), string::utf8(b"INIT"));
        let denom = metadata_to_denom(metadata);
        let denom_ = metadata_to_denom(metadata_);
        let metadata_from_denom = denom_to_metadata(denom);
        let metadata_from_denom_ = denom_to_metadata(denom_);
        assert!(metadata == metadata_from_denom, 0);
        assert!(metadata_ == metadata_from_denom_, 1);
    }
}