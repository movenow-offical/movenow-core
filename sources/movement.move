module movenow::movement {
    use std::signer::address_of;
    use std::string::String;
    use std::vector;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_std::smart_vector;
    use aptos_std::smart_vector::SmartVector;

    // errors
    const ERR_INVALID_ID : u64 = 1;
    const ERR_ALREADY_CLAIMED : u64 = 2;
    const ERR_REACH_MAX_AMOUNT : u64 = 3;

    struct MovementStore has key, store {
        movements: SmartVector<Movement>,
        owner_index: SmartTable<address, SmartVector<u64>>,
    }

    struct Movement has store {
        id: u64,
        name: String,
        description: String,
        image_url: String,
        max_amount: u64,
        owners: SmartVector<address>,
        creator: address,
    }

    fun init_module(account: &signer) {
        let movement_store = MovementStore {
            movements: smart_vector::new(),
            owner_index: smart_table::new(),
        };
        move_to(account, movement_store);
    }

    public entry fun create_movement(account: signer, name: String, description: String, image_url: String, max_amount: u64) acquires MovementStore {
        let movement_store = borrow_global_mut<MovementStore>(@movenow);
        let id = smart_vector::length(&movement_store.movements);
        let movement = Movement {
            id,
            name,
            description,
            image_url,
            max_amount,
            owners: smart_vector::new(),
            creator: address_of(&account),
        };
        smart_vector::push_back(&mut movement_store.movements, movement);
    }

    public entry fun mint_movement(account: signer, movement_id: u64) acquires MovementStore {
        let movement_store = borrow_global_mut<MovementStore>(@movenow);
        assert!(movement_id < smart_vector::length(&movement_store.movements), ERR_INVALID_ID);
        let movement = smart_vector::borrow_mut(&mut movement_store.movements, movement_id);
        assert!(movement.max_amount > smart_vector::length(&movement.owners), ERR_REACH_MAX_AMOUNT);
        if(!smart_table::contains(&movement_store.owner_index, address_of(&account))) {
            smart_table::add(&mut movement_store.owner_index, address_of(&account), smart_vector::new());
        };
        let owned_movements = smart_table::borrow_mut(&mut movement_store.owner_index, address_of(&account));
        assert!(!smart_vector::contains(owned_movements, &movement_id), ERR_ALREADY_CLAIMED);
        smart_vector::push_back(owned_movements, movement_id);
        smart_vector::push_back(&mut movement.owners, address_of(&account));
    }

    struct MovementView has drop {
        id: u64,
        name: String,
        description: String,
        image_url: String,
        max_amount: u64,
        mint_count: u64,
        creator: address,
    }

    #[view]
    public fun get_movement(id: u64): MovementView acquires MovementStore {
        let movement_store = borrow_global<MovementStore>(@movenow);
        assert!(id < smart_vector::length(&movement_store.movements), ERR_INVALID_ID);
        let movement = smart_vector::borrow(&movement_store.movements, id);
        let mint_count = smart_vector::length(&movement.owners);
        MovementView {
            id: movement.id,
            name: movement.name,
            description: movement.description,
            image_url: movement.image_url,
            max_amount: movement.max_amount,
            mint_count,
            creator: movement.creator,
        }
    }

    #[view]
    public fun get_movement_owners(id: u64, offset: u64, len: u64): vector<address> acquires MovementStore {
        let movement_store = borrow_global<MovementStore>(@movenow);
        assert!(id < smart_vector::length(&movement_store.movements), ERR_INVALID_ID);
        let movement = smart_vector::borrow(&movement_store.movements, id);
        let owners = vector::empty<address>();
        let owner_num = smart_vector::length(&movement.owners);
        let i = 0;
        loop {
            if(i > len || i + offset >= owner_num) {
                break
            };
            let owner = smart_vector::borrow(&movement.owners, i + offset);
            vector::push_back(&mut owners, *owner);
            i = i + 1;
        };
        owners
    }

    #[view]
    public fun get_movements(offset: u64, len: u64): vector<MovementView> acquires MovementStore {
        let movement_store = borrow_global<MovementStore>(@movenow);
        let result = vector::empty<MovementView>();
        let movement_num = smart_vector::length(&movement_store.movements);
        if(offset >= movement_num) {
            return result
        };
        // return in reverse order
        let current = movement_num - offset - 1;
        let i = 0;
        loop {
            if(i >= len) {
                break
            };
            let movement = smart_vector::borrow(&movement_store.movements, current);
            let mint_count = smart_vector::length(&movement.owners);
            let movement_view = MovementView {
                id: movement.id,
                name: movement.name,
                description: movement.description,
                image_url: movement.image_url,
                max_amount: movement.max_amount,
                mint_count,
                creator: movement.creator,
            };
            vector::push_back(&mut result, movement_view);
            i = i + 1;
            if(current == 0) {
                break
            };
            current = current - 1;
        };
        result
    }

    #[view]
    public fun get_user_movements(account: address): vector<u64> acquires MovementStore {
        let movement_store = borrow_global<MovementStore>(@movenow);
        if(!smart_table::contains(&movement_store.owner_index, account)) {
            return vector::empty<u64>()
        };
        let movement_ids = smart_table::borrow(&movement_store.owner_index, account);
        smart_vector::to_vector(movement_ids)
    }
}
