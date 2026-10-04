"""Same-rig right-hand and two-hand animation baking in Blender."""
import bpy
from mathutils import Vector

def right_handed(path, repair=False):
    """Bake two-hand long-gun actions and mirror the authored rig's handedness."""
    bpy.ops.wm.open_mainfile(filepath=str(path))
    if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
    rig = bpy.data.objects['CharacterArmature']
    if rig.get('zombie_slop_handedness') == 'right' and not repair:
        return path
    # Retain the original clips and detach the previous handedness transform.
    old_mirror = bpy.data.objects.get('RightHandedRig')
    if old_mirror:
        old_mirror.scale.x = 1
        bpy.context.view_layer.update()
        for child in list(old_mirror.children):
            world = child.matrix_world.copy()
            child.parent = None
            child.matrix_world = world
        bpy.data.objects.remove(old_mirror, do_unlink=True)
    for gun in ('Rifle', 'Shotgun', 'CompactShotgun', 'SMG', 'Revolver', 'Pistol'):
        old_fore = bpy.data.objects.get(gun + 'ForeGrip')
        if old_fore:
            bpy.data.objects.remove(old_fore, do_unlink=True)
    for action in list(bpy.data.actions):
        if action.name.endswith(('_Rifle', '_Shotgun', '_CompactShotgun', '_SMG', '_Revolver', '_Pistol')):
            bpy.data.actions.remove(action)
    rig.animation_data.action = bpy.data.actions['Idle_Gun']
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    main = bpy.data.objects.new('LongGunWristTarget', None)
    bpy.context.collection.objects.link(main)
    main.location = rig.matrix_world @ (Vector((.10, -.04, 1.08)) / 1.15)
    orientation = bpy.data.objects.new('LongGunHandOrientation', None)
    bpy.context.collection.objects.link(orientation)
    finger = rig.pose.bones['Middle1.L']
    barrel = bpy.data.objects['RifleMuzzle'].matrix_world.translation - bpy.data.objects['RifleGrip'].matrix_world.translation
    hand_rotation = (rig.matrix_world @ finger.matrix).to_quaternion()
    correction = barrel.normalized().rotation_difference(Vector((0, -1, 0)))
    orientation.rotation_mode = 'QUATERNION'
    orientation.rotation_quaternion = correction @ hand_rotation
    primary = rig.pose.bones['LowerArm.L'].constraints.new('IK')
    primary.target = main
    primary.chain_count = 2
    primary.use_stretch = False
    hand = finger.constraints.new('COPY_ROTATION')
    hand.target = orientation
    hand.owner_space = 'WORLD'
    hand.target_space = 'WORLD'
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    for gun in ('Rifle', 'Shotgun', 'CompactShotgun', 'SMG', 'Revolver', 'Pistol'):
        weapon = bpy.data.objects[gun]
        fore = bpy.data.objects.new(gun + 'ForeGrip', None)
        bpy.context.collection.objects.link(fore)
        fore.parent = weapon
        fore.location = bpy.data.objects[gun + 'Grip'].location.lerp(bpy.data.objects[gun + 'Muzzle'].location, .32)
        for clip, original in [('Idle', 'Idle_Gun'), ('Walk', 'Walk_Gun'), ('Run', 'Run_Gun'),
                               ('Aim', 'Aim'), ('Shoot', 'Shoot'), ('Reload', 'Reload'),
                               ('LowerIdle', 'Idle'), ('LowerWalk', 'Walk'), ('LowerRun', 'Run')]:
            lowered = clip.startswith('Lower')
            main.location = rig.matrix_world @ (Vector((.17, -.14, .88) if lowered else (.10, -.04, 1.08)) / 1.15)
            direction = Vector((0, -.8, -.6)) if lowered else Vector((0, -1, 0))
            orientation.rotation_quaternion = Vector((0, -1, 0)).rotation_difference(direction) @ correction @ hand_rotation
            # Derive each target from the unchanged author pose, not the last baked action.
            rig.animation_data.action = bpy.data.actions['Idle_Gun'];bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
            orientation.rotation_quaternion = Vector((0, -1, 0)).rotation_difference(direction) @ correction @ hand_rotation
            action = bpy.data.actions[original].copy()
            action.name = clip + '_' + gun
            action.use_fake_user = True
            rig.animation_data.action = action
            primary.influence = hand.influence = 1
            end = max(1, int(action.frame_range[1]))
            bpy.ops.nla.bake(frame_start=0, frame_end=max(1, int(action.frame_range[1])),
                            step=1, only_selected=False, visual_keying=True,
                            clear_constraints=False, use_current_action=True, bake_types={'POSE'})
            # A target parented to a gun on the same armature creates a dependency
            # cycle. Sample the foregrip into a separate world-space target first.
            primary.influence = hand.influence = 0
            target = bpy.data.objects.new('BakedSupportTarget', None)
            bpy.context.collection.objects.link(target)
            for frame in range(end + 1):
                bpy.context.scene.frame_set(frame)
                bpy.context.view_layer.update()
                # Lower-arm IK ends at the wrist. Offset the fingertip-sized
                # foregrip so the palm, rather than the elbow, meets the weapon.
                target.location = fore.matrix_world.translation + Vector((0, .035, -.025))
                target.keyframe_insert(data_path='location', frame=frame)
            support = rig.pose.bones['LowerArm.R'].constraints.new('IK')
            support.target = target
            support.chain_count = 2
            support.use_stretch = False
            support.influence = (0 if gun in ('Pistol', 'Revolver') else (.45 if clip == 'Reload' else 1))
            bpy.ops.nla.bake(frame_start=0, frame_end=end, step=1, only_selected=False,
                            visual_keying=True, clear_constraints=False,
                            use_current_action=True, bake_types={'POSE'})
            rig.pose.bones['LowerArm.R'].constraints.remove(support)
            target_action = target.animation_data.action
            bpy.data.objects.remove(target, do_unlink=True)
            bpy.data.actions.remove(target_action)
    rig.pose.bones['LowerArm.L'].constraints.remove(primary)
    finger.constraints.remove(hand)
    for obj in (main, orientation):
        bpy.data.objects.remove(obj, do_unlink=True)
    rig.animation_data.action = bpy.data.actions['Idle_Gun']
    mirror = bpy.data.objects.new('RightHandedRig', None)
    bpy.context.collection.objects.link(mirror)
    for obj in list(bpy.context.scene.objects):
        if obj != mirror and obj.parent is None:
            obj.parent = mirror
    mirror.scale.x = -1
    rig['zombie_slop_handedness'] = 'right'
    rig['zombie_slop_two_hand_pose_version'] = 2
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    return path
