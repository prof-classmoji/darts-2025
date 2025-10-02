/*
    This file is part of darts – the Dartmouth Academic Ray Tracing Skeleton.

    Copyright (c) 2017-2025 by Wojciech Jarosz
*/

#include "darts/json.h"
#include <darts/scene.h>
#include <darts/progress.h>
#include <darts/stats.h>
#include <fstream>
#include <spdlog/sinks/stdout_sinks.h>

uint32_t Scene::random_seed = 53;

/// Construct a new scene from a json object
Scene::Scene(const json &j) { parse(j); }

Scene::~Scene() {}

Color3f Scene::background(const Ray3f &ray) const
{
    return m_background;
}

bool Scene::intersect(const Ray3f &ray, HitRecord &hit) const
{
    ++g_num_traced_rays;
    return m_surfaces->intersect(ray, hit);
}

// compute the color corresponding to a ray by raytracing
Color3f Scene::recursive_color(const Ray3f &ray, int depth) const
{
    constexpr int max_depth = 64;
    put_your_code_here("Assignment 1: Insert your recursive_color() code here");
    return Color3f(0.0f, 0.0f, 0.0f);

    // TODO: Recursively raytrace the scene, similar to the code you wrote in darts_tutorial1
    //       Different to before, you should also take into account surfaces that are self-emitting
    // Pseudo-code:
    //
    // if scene.intersect:
    //      get emitted color (hint: you can use hit.mat->emitted)
    // 		if depth < max_depth and hit_material.scatter(....) is successful:
    //			recursive_color = call this function recursively with the scattered ray and increased depth
    //          return emitted color + attenuation * recursive_color
    //		else
    //			return emitted color;
    // else:
    // 		return background color (hint: look at background())
}

// raytrace an image
Image3f Scene::raytrace(const string &outfile, const string &outfile_hdr) const
{
    // allocate an image of the proper size
    auto image = Image3f(m_camera->resolution().x, m_camera->resolution().y);

    put_your_code_here("Assignment 1: insert your raytrace() code here");

    // TODO: Render the image, similar to the tutorial
    // Pseudo-code:
    //
    // foreach image row (go over image height)
    //     foreach pixel in the row (go over image width)
    //         init accumulated color to zero
    //         repeat m_num_samples times:
    //             compute a random point within the pixel (you can just add a random number between 0 and 1
    //                                                      to the pixel coordinate. You can use randf() for
    //                                                      this)
    //             compute camera ray
    //             accumulate color raytraced with the ray (by calling recursive_color)
    //         divide color by the number of pixel samples

    // Hint: you can create a Progress object (progress.h) to provide a
    // progress bar during rendering.

    // the code below finalizes and prints out the statistics gathered during rendering
    accumulate_thread_stats();
    spdlog::info(stats_report());
    clear_stats();

    spdlog::info("Writing rendered image to file \"{}\"...", outfile);
    // We'll include the original json data as additional metadata to save with the exr file.
    // This can be really helpful when you later look at your rendered images and wonder what settings where used.
    auto metadata = json{{"scene", m_json.dump(4)}, {"comments", "Rendered with darts"}};
    image.save(outfile, 1.f, metadata);

    // if the outfile wasn't specified, also save the rendering in .exr format
    if (!outfile_hdr.empty())
    {
        spdlog::info("Writing rendered image to file \"{}\"...", outfile_hdr);
        image.save(outfile_hdr, 1.f, metadata);
    }

    spdlog::info("done!");

    // return the ray-traced image
    return image;
}
